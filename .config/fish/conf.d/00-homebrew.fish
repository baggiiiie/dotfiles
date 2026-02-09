### Bootstrap Homebrew PATH early (before other conf.d scripts) ###
if test (uname) = Darwin; and test -x /opt/homebrew/bin/brew
    fish_add_path --prepend /opt/homebrew/bin /opt/homebrew/sbin
end
