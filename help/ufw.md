# Rule Syntax
	ufw [rule]
	  [delete] [insert NUM] [prepend]
	  allow|deny|reject|limit
	  [in|out [on INTERFACE]]
	  [log|log-all]
	  [proto PROTOCOL]
	  [from ADDRESS [port PORT | app APPNAME ]]
	  [to ADDRESS [port PORT | app APPNAME ]]
	  [comment COMMENT]

# Cheat Sheet
From https://gist.github.com/drAlberT/17e1f67f1e566c2ded50

	ufw [--dry-run] enable|disable|reload
	ufw [--dry-run] default allow|deny|reject [incoming|outgoing]
	ufw [--dry-run] logging on|off|LEVEL
	    toggle logging. Logged packets use the LOG_KERN syslog facility. Systems configured for rsyslog
	    support may also log to /var/log/ufw.log. Specifying a LEVEL turns logging on for the specified LEVEL.
	    The default log level is 'low'.
	ufw [--dry-run] reset
	ufw [--dry-run] status [verbose|numbered]
	ufw [--dry-run] show REPORT
	ufw [--dry-run] [delete] [insert NUM] allow|deny|reject|limit [in|out] [log|log-all] PORT[/protocol]
	ufw [--dry-run] [delete] [insert NUM] allow|deny|reject|limit [in|out on INTERFACE] [log|log-all]
	    [proto protocol] [from ADDRESS [port PORT]] [to ADDRESS [port PORT]]
	ufw [--dry-run] delete NUM
	ufw [--dry-run] app list|info|default|update

# Examples
	ufw status verbose
	ufw app list
	ufw allow in on eth0 log from any to any app SSH-22022
	ufw [delete] allow in proto udp from 193.204.114.105 to 12.34.56.78 port 123
