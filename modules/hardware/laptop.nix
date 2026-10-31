{ pkgs, ... }:
{
  # Things that only make sense on a machine that travels: idle suspend with
  # a hard power-off after a long sleep, and Intel thermal management.

  ##### Power #####
  services.logind.settings.Login = {
    # Idle for 1 hour of no input -> automatically suspend
    IdleAction = "suspend";
    IdleActionSec = "1h";
  };

  # When the system suspends after 1 hour of idle, set an RTC alarm for 15 hours
  # later (15h = 54000s; total 16 hours from last user activity). On wake, if
  # 15 hours have elapsed, power off completely.
  environment.etc."systemd/system-sleep/rtc-poweroff".source =
    pkgs.writeShellScript "rtc-poweroff" ''
      target=/run/rtc-poweroff-target
      case "$1/$2" in
        pre/suspend)
          # 15 hours = 54000 seconds (1h idle + 15h sleep = 16h total from last activity)
          echo $(( $(${pkgs.coreutils}/bin/date +%s) + 54000 )) > "$target"
          ${pkgs.util-linux}/bin/rtcwake -m no -s 54000
          ;;
        post/suspend)
          if [ -f "$target" ] \
             && [ "$(${pkgs.coreutils}/bin/date +%s)" -ge "$(( $(${pkgs.coreutils}/bin/cat "$target") - 60 ))" ]; then
            ${pkgs.coreutils}/bin/rm -f "$target"
            ${pkgs.systemd}/bin/systemctl poweroff
          fi
          ${pkgs.coreutils}/bin/rm -f "$target"
          ;;
      esac
    '';

  services.thermald.enable = true;  # Intel thermal management
}
