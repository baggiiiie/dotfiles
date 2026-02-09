#!/usr/bin/env node

import { chromium } from "playwright";
import { join } from "path";
import { homedir } from "os";

const TIMESHEET_URL =
    "https://sapfioriprd.illumina.com/sap/bc/ui5_ui5/ui2/ushell/shells/abap/FioriLaunchpad.html?sap-client=100&sap-language=EN#ZSTIME_PLW-Create";
const HOURS = "8";
const USER_DATA_DIR = join(homedir(), "Library", "Caches", "timesheet-chrome");

const SSO_USERNAME = process.env.ILLUMINA_USERNAME;
const SSO_PASSWORD = process.env.ILLUMINA_PASSWORD;

async function handleSSO(page) {
    const url = page.url();

    // Okta login page with username/password form
    if (url.includes("okta") || url.includes("login") || url.includes("sso")) {
        console.log("SSO login page detected, filling credentials...");

        // if (!SSO_USERNAME || !SSO_PASSWORD) {
        //     console.error(
        //         "ILLUMINA_USERNAME and ILLUMINA_PASSWORD env variables are required for SSO login."
        //     );
        //     process.exit(1);
        // }

        // Try Okta-style login form
        const usernameField = page.locator(
            'input[name="identifier"], input[name="username"], input[id="okta-signin-username"], input[type="email"]'
        );
        if ((await usernameField.count()) > 0 && SSO_USERNAME != null) {
            await usernameField.first().fill(SSO_USERNAME);

            // Some Okta flows have a "Next" button before the password field
            const nextButton = page.locator(
                'input[type="submit"], button[type="submit"]'
            );
            if ((await nextButton.count()) > 0) {
                await nextButton.first().click();
                await page.waitForTimeout(2000);
            }
        }

        const passwordField = page.locator(
            'input[name="credentials.passcode"], input[name="password"], input[id="okta-signin-password"], input[type="password"]'
        );
        if ((await passwordField.count()) > 0 && SSO_PASSWORD) {
            await passwordField.first().fill(SSO_PASSWORD);
        }

        const signInButton = page.locator(
            'input[type="submit"], button[type="submit"]'
        );
        if ((await signInButton.count()) > 0) {
            await signInButton.first().click();
        }

        console.log("SSO credentials submitted, waiting for redirect...");
        await page.waitForTimeout(5000);
    }
}

async function fillTimesheet() {
    const headless = process.env.HEADLESS === "true" || process.env.HEADLESS === "1";
    const context = await chromium.launchPersistentContext(USER_DATA_DIR, {
        headless,
        channel: "chrome",
        args: ["--disable-blink-features=AutomationControlled"],
    });

    const page = context.pages()[0] || (await context.newPage());

    console.log("Navigating to timesheet...");
    await page.goto(TIMESHEET_URL, { waitUntil: "domcontentloaded" });
    await page.waitForTimeout(3000);

    // Handle SSO if redirected to login page
    if (!page.url().includes("sapfioriprd.illumina.com")) {
        await handleSSO(page);
        await page.waitForURL("**/sapfioriprd.illumina.com/**", {
            timeout: 60_000,
        });
    }

    console.log("Waiting for timesheet to load...");
    await page.waitForSelector('text="Illumina Run Manager (EdgeOS)"', {
        timeout: 60_000,
    });
    await page.waitForTimeout(2000);

    // Find the EdgeOS row and fill Mon-Fri (first 5 input fields in that row)
    const row = page.locator('tr:has-text("Illumina Run Manager (EdgeOS)")');
    const inputs = row.locator("input[type='number'], input.sapMInputBaseInner");
    const count = await inputs.count();

    if (count < 7) {
        console.error(`Expected at least 7 day fields, found ${count}. Aborting.`);
        await context.close();
        process.exit(1);
    }

    // Check if already filled
    const monValue = await inputs.nth(0).inputValue();
    if (monValue !== "0" && monValue !== "") {
        console.log(
            `Timesheet already has values (Mon=${monValue}). Skipping fill.`
        );
        await context.close();
        return;
    }

    console.log("Filling 8 hours Mon-Fri...");
    for (let i = 0; i < 5; i++) {
        const input = inputs.nth(i);
        await input.click();
        await input.fill(HOURS);
    }
    // Click away to trigger update
    await row.locator("td").first().click();
    await page.waitForTimeout(1000);

    console.log("Saving timesheet...");
    await page.getByRole("button", { name: "Save" }).click();

    // Handle confirmation dialog
    await page.waitForSelector('text="Are you sure"', { timeout: 10_000 });
    await page.getByRole("button", { name: "Submit" }).click();

    // Wait for success
    await page.waitForSelector('text="succcessfully submitted"', {
        timeout: 30_000,
    });
    console.log("Timesheet submitted successfully (40 hours).");

    await page.waitForTimeout(2000);
    await context.close();
}

fillTimesheet().catch((err) => {
    console.error("Failed:", err.message);
    process.exit(1);
});
