#!/usr/bin/env node

import { chromium } from "playwright";
import { join } from "path";
import { homedir } from "os";
import { execSync } from "child_process";

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
        try {
            execSync(
                "terminal-notifier -message 'login!' -title fill-timesheet -sound ping"
            );
        } catch (e) {
            console.warn("Failed to send terminal notification:", e.message);
        }
        await page.waitForTimeout(50000);
    }
}

async function fillTimesheet() {
    const headless = process.env.HEADLESS === "true" || process.env.HEADLESS === "1";
    let context;
    try {
        context = await chromium.launchPersistentContext(USER_DATA_DIR, {
            headless,
            channel: "chrome",
            args: ["--disable-blink-features=AutomationControlled"],
        });
    } catch (err) {
        throw new Error(
            `Failed to launch Chrome (headless=${headless}, userDataDir=${USER_DATA_DIR}): ${err.message}`
        );
    }

    const page = context.pages()[0] || (await context.newPage());

    console.log("Navigating to timesheet...");
    try {
        await page.goto(TIMESHEET_URL, { waitUntil: "domcontentloaded" });
    } catch (err) {
        throw new Error(`Failed to navigate to ${TIMESHEET_URL}: ${err.message}`);
    }
    await page.waitForTimeout(3000);

    // Handle SSO if redirected to login page
    const currentUrl = page.url();
    if (!currentUrl.includes("sapfioriprd.illumina.com")) {
        console.log(`Redirected to SSO (url=${currentUrl})`);
        await handleSSO(page);
        try {
            await page.waitForURL("**/sapfioriprd.illumina.com/**", {
                timeout: 60_000,
            });
        } catch (err) {
            throw new Error(
                `Timed out waiting for redirect back to SAP after SSO (stuck on ${page.url()}): ${err.message}`
            );
        }
    }

    console.log("Waiting for timesheet to load...");
    try {
        await page.waitForSelector('text="Illumina Run Manager (EdgeOS)"', {
            timeout: 60_000,
        });
    } catch (err) {
        const bodyText = await page.textContent("body").catch(() => "<unreadable>");
        throw new Error(
            `Timed out waiting for "Illumina Run Manager (EdgeOS)" row to appear (url=${page.url()}).\n` +
            `  Page text preview: ${bodyText.slice(0, 500)}\n` +
            `  Original error: ${err.message}`
        );
    }
    await page.waitForTimeout(2000);

    // Find the EdgeOS row and fill Mon-Fri (first 5 input fields in that row)
    const row = page.locator('tr:has-text("Illumina Run Manager (EdgeOS)")');
    const inputs = row.locator("input[type='number'], input.sapMInputBaseInner");
    const count = await inputs.count();

    if (count < 7) {
        const rowHtml = await row.innerHTML().catch(() => "<unreadable>");
        console.error(`Expected at least 7 day fields, found ${count}. Aborting.`);
        console.error(`Row HTML: ${rowHtml.slice(0, 1000)}`);
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
    // Click away to trigger update (first td is a hidden SAP decoration cell, skip it)
    await row.locator("td:visible").first().click();
    await page.waitForTimeout(1000);

    console.log("Saving timesheet...");
    const saveButton = page.getByRole("button", { name: "Save" });
    if (!(await saveButton.isVisible())) {
        throw new Error("Save button not found or not visible on the page");
    }
    await saveButton.click();
    await page.waitForTimeout(1000);

    // SAP UI5 sometimes needs a more forceful click — retry with dispatchEvent if
    // the confirmation dialog doesn't show up quickly.
    const confirmDialog = page.locator('text=/are you sure/i');
    if (!(await confirmDialog.isVisible({ timeout: 3000 }).catch(() => false))) {
        console.log("Confirmation dialog not visible yet, retrying Save click...");
        await saveButton.dispatchEvent("click");
        await page.waitForTimeout(1000);
    }

    // Handle confirmation dialog
    try {
        await confirmDialog.waitFor({ state: "visible", timeout: 10_000 });
    } catch (err) {
        const screenshotPath = join(homedir(), "timesheet-debug.png");
        await page.screenshot({ path: screenshotPath, fullPage: true }).catch(() => {});
        const bodyText = await page.textContent("body").catch(() => "<unreadable>");
        throw new Error(
            `Confirmation dialog ("Are you sure") did not appear after clicking Save (url=${page.url()}).\n` +
            `  Screenshot saved to: ${screenshotPath}\n` +
            `  Page text preview: ${bodyText.slice(0, 500)}\n` +
            `  Original error: ${err.message}`
        );
    }
    const submitButton = page.getByRole("button", { name: /submit/i });
    // Fall back to "OK" / "Yes" buttons common in SAP confirmation dialogs
    const okButton = page.getByRole("button", { name: /^(ok|yes)$/i });
    if (await submitButton.isVisible().catch(() => false)) {
        await submitButton.click();
    } else if (await okButton.first().isVisible().catch(() => false)) {
        console.log('No "Submit" button found, clicking OK/Yes instead.');
        await okButton.first().click();
    } else {
        throw new Error("Confirmation dialog appeared but no Submit/OK/Yes button found");
    }

    // Wait for success
    try {
        await page.waitForSelector('text=/successfully submitted/i', {
            timeout: 30_000,
        });
    } catch (err) {
        const bodyText = await page.textContent("body").catch(() => "<unreadable>");
        throw new Error(
            `Did not see success message after submitting (url=${page.url()}).\n` +
            `  Page text preview: ${bodyText.slice(0, 500)}\n` +
            `  Original error: ${err.message}`
        );
    }
    console.log("Timesheet submitted successfully (40 hours).");

    await page.waitForTimeout(2000);
    await context.close();
}

fillTimesheet().catch((err) => {
    console.error("Failed:", err.message);
    if (err.message !== err.stack) {
        console.error("Stack trace:", err.stack);
    }
    process.exit(1);
});
