### Bootstrap Homebrew PATH early (before other conf.d scripts) ###
if test -d /opt/homebrew
    fish_add_path --prepend /opt/homebrew/bin /opt/homebrew/sbin
end
