#!/usr/bin/env bash

# ---
# cloudflare-cli v1.0.1
# ---

# -- Variables
VERSION=1.0.1
debug=0
details=0
quiet=0
NL=$'\n'
TA=$'\t'
APIv4_ENDPOINT=https://api.cloudflare.com/client/v4

# - Help text
usage_text=\
"Usage: cloudflare [Options] <command> <parameters>

Commands:
   show, add, delete, change, clear, invalidate, check

Options:
 --details, -d    Display detailed info where possible
 --debug, -D      Display API debugging info
 --quiet, -q      Less verbose
 -E <email>
 -T <api_token>
Environment variables:
 CF_ACCOUNT  -  email address (as -E option)
 CF_TOKEN    -  API token (as -T option)

Configuration file for credentials:
 Create a file in \$HOME/.cloudflare with both CF_ACCOUNT and CF_TOKEN defined.

 CF_ACCOUNT=example@example.com
 CF_TOKEN=<token>

Version $version
Enter \"cloudflare help\" to list available commands."

# -------------------------------------------------- #

# - die function, need to figure out what this is for.
die() {
	if [ -n "$1" ];	then
		echo "$1" >&2
	fi
	exit ${2:-1}
}

# - Check bash version and die if not at least 4.0
if [ $BASH_VERSINFO -lt 4 ]; then
	die "Sorry, you need at least bash 4.0 to run this script." 1
fi

# - Small funcs yay
is_debug() { [ "$debug" = 1 ]; }
is_quiet() { [ "$quiet" = 1 ]; }
is_integer() { expr "$1" : '[0-9]\+$' >/dev/null; }
is_hex() { expr "$1" : '[0-9a-fA-F]\+$' >/dev/null; }

# - Main call, I think?
call_cf_v4()
{
	# Invocation: call_cf_v4 <METHOD> <PATH> [PARAMETERS] [-- JSON-DECODER-ARGS]
	local method path formtype exitcode querystring page per_page
	declare -a curl_opts
	curl_opts=()
	
	method=${1^^}
	shift
	path=$1
	shift
	
	if [ "$method" != POST -o "${1:0:1}" = '{' ]
	then
		curl_opts+=(-H "Content-Type: application/json")
		formtype=data
	else
		formtype=form
	fi
	if [ "$method" = GET ]
	then
		curl_opts+=(--get)
	fi
	
	while [ -n "$1" ]
	do
		if [ ."$1" = .-- ]
		then
			shift
			break
		else
			curl_opts+=(--$formtype "$1")
		fi
		shift
	done
	if [ -z "$1" ]
	then
		set -- '&?success?"success"?"failed"'
	fi
	
	page=1
	per_page=50
	while true
	do
		querystring="?page=$page&per_page=$per_page"
		if is_debug
		then
			echo "<<< curl -X $method ${curl_opts[*]} $APIv4_ENDPOINT$path$querystring" >&2
		fi
		
		output=`curl -sS -H "X-Auth-Email: $CF_ACCOUNT" -H "X-Auth-Key: $CF_TOKEN" \
			-X "$method" "${curl_opts[@]}" \
			"$APIv4_ENDPOINT$path$querystring" | json_decode "$@"`
		exitcode=$?
		sed -e '/^!/d' <<<"$output"
		
		if grep -qE '^!has_more' <<<"$output"
		then
			let page++
		else
			break
		fi
	done
	return $exitcode
}

json_decode()
{
	# Parameter Synatx
	#
	# .key1.key11.key111
	#    dive into array
	# %format
	#    set output formatting
	# table
	#    display as a table
	# ,mod1,mod2,...
	#    see modifiers
	# &mod1&mod2&...
	#    modifiers per line
	#
	#
	# Modifier Synatx
	#
	# ?modCondition?modTrue?modFalse
	#    tenary expression
	# ||key1||key2||key3||...
	#    find a true-ish value
	# key.subkey.subsubkey
	#    dive into array
	# !key
	#    implode non-zero elements of key
	# !!key1 key2 key3 ...
	#    implode values of keys if they are not false
	# <code
	#    evaluate code, keyN are in $keyN
	# "string"
	#    literal
	# @suffixKey@stringKey
	#    trim suffix from string
	# key
	#    represent the value
	
	php -r '
		function notzero($e)
		{
			return $e!=0;
		}
		function repr_array($a, $brackets=false)
		{
			if(is_array($a))
			{
				$o = array();
				foreach($a as $k => $v)
				{
					$o[] = (is_int($k) ? "" : "$k=") . repr_array($v, true);
				}
				if(count($o) > 1 and $brackets)
					return "[" . implode(",", $o) . "]";
				else
					return implode(",", $o);
			}
			else
				return $a;
		}
		function pfmt($fmt, &$array, $care_null=1)
		{
			if(preg_match("/^\?(.*?)\?(.*?)\?(.*)/", $fmt, $grp))
			{
				$out = pfmt($grp[1], $array, 0) ? pfmt($grp[2], $array) : pfmt($grp[3], $array);
			}
			elseif(preg_match("/^!!(.*)/", $fmt, $grp))
			{
				$out = implode(",", array_filter(preg_split("/\s+/", $grp[1]), function($k) use($array){ return !!$array[$k]; }));
			}
			elseif(preg_match("/^!(.*)/", $fmt, $grp))
			{
				$out = implode(",", array_keys(array_filter($array[$grp[1]], "notzero")));
			}
			elseif(preg_match("/^<(.*)/", $fmt, $grp))
			{
				$code = $grp[1];
				extract($array, EXTR_SKIP);
				$out = eval("return $code;");
			}
			elseif(preg_match("/^\x22(.*?)\x22/", $fmt, $grp))
			{
				$out = $grp[1];
			}
			elseif(preg_match("/^@(.*?)@(.*)/", $fmt, $grp))
			{
				$out = substr($array[$grp[2]], 0, -strlen(".".$array[$grp[1]]));
				if($out == "") $out = "@";
			}
			elseif(preg_match("/^\|\|/", $fmt))
			{
				while(preg_match("/^\|\|(.*?)(\|\|.*|$)/", $fmt, $grp))
				{
					if(pfmt($grp[1], $array, 0) != false or !preg_match("/^\|\|/", $grp[2]))
					{
						$out = pfmt($grp[1], $array, $care_null);
						break;
					}
					$fmt = $grp[2];
				}
			}
			elseif(preg_match("/(.+?)\.(.+)/", $fmt, $grp))
			{
				if(is_array(@$array[$grp[1]]))
					$out = pfmt($grp[2], $array[$grp[1]], $care_null);
				else
					$out = NULL;
			}
			else
			{
				/* Fix Cludflare´s DNS notation.
				   We must use FQDN with the trailing dot if no $ORIGIN declared. */
				if(in_array(@$array["type"], explode(",", "CNAME,MX,NS,SRV")) and isset($array["content"]) and substr($array["content"], -1) != ".")
				{
					$array["content"] .= ".";
				}
				if(is_array(@$array[$fmt]))
				{
					$out = repr_array($array[$fmt]);
				}
				else
				{
					$out = $care_null ? (array_key_exists($fmt, $array) ? (isset($array[$fmt]) ? $array[$fmt] : "NULL" ) : "NA") : @$array[$fmt];
				}
			}
			return $out;
		}
		
		$data0 = json_decode(file_get_contents("php://stdin"), true);
		if('$debug') file_put_contents("php://stderr", var_export($data0, 1));
		if(@$data0["result"] == "error")
		{
			echo $data0["msg"] . "\n";
			exit(2);
		}
		if(array_key_exists("success", $data0) and !$data0["success"])
		{
			function prnt_error($e)
			{
				printf("E%s: %s\n", $e["code"], $e["message"]);
				foreach((array)@$e["error_chain"] as $e) prnt_error($e);
			}
			foreach($data0["errors"] as $e) prnt_error($e);
			exit(2);
		}
		
		if(isset($data0["result_info"]["page"]) and $data0["result_info"]["page"] < $data0["result_info"]["total_pages"])
		{
			echo "!has_more\n";
		}
		
		array_shift($argv);
		$data = $data0;
		foreach($argv as $param)
		{
			if($param == "")
			{
				continue;
			}
			if(substr($param, 0, 1) == ".")
			{
				$data = $data0;
				foreach(explode(".", $param) as $p)
				{
					if($p != "")
					{
						if(array_key_exists($p, $data))
						{
							if($p == "objs" and @$data["has_more"])
							{
								echo "!has_more\n";
								echo "!count=", $data["count"], "\n";
							}
							$data = $data[$p];
						}
						else
						{
							$data = array();
							break;
						}
					}
				}
			}
			if(substr($param, 0, 1) == "%")
			{
				$outfmt = substr($param, 1);
			}
			if($param == "table")
			{
				ksort($data);
				$maxlength = 0;
				foreach($data as $key=>$elem)
				{
					if(strlen($key) > $maxlength)
					{
						$maxlength = strlen($key);
					}
				}
				foreach($data as $key=>$elem)
				{
					printf("%-".$maxlength."s\t%s\n", $key, (string)$elem);
				}
			}
			if(substr($param, 0, 1) == ",")
			{
				foreach($data as $key=>$elem)
				{
					$out = array();
					foreach(preg_split("/(?<!,),(?!,)/", $param) as $p)
					{
						$p = str_replace(",,", ",", $p);
						if($p != "")
						{
							$out[] = pfmt($p, $elem);
						}
					}
					if(isset($outfmt))
					{
						vprintf($outfmt, $out);
					}
					else
					{
						echo implode("\t", $out), "\n";
					}
				}
			}
			if(substr($param, 0, 1) == "&")
			{
				foreach(explode("&", $param) as $p)
				{
					if($p!="")
					{
						echo pfmt($p, $data), "\n";
					}
				}
			}
		}
	' "$@"
}

findout_record()
{
	# arguments:
	#   $1 - record name (eg: sub.example.com)
	#   $2 - record type, optional (eg: CNAME)
	#   $3 - 0/1, stop searching at first match, optional
	#   $4 - record content to match to
	# writes global variables: zone, zone_id, record_id, record_type, record_ttl, record_content
	# return code:
	#   0 - zone and record are found and stored in zone, zone_id, record_id, record_type, record_ttl, record_content
	#   2 - no suitable zone found
	#   3 - no matching record found
	#   4 - more than 1 matching record found
	
	local record_name=${1,,}
	declare -g record_type=${2^^}
	local first_match=$3
	local record_oldcontent=$4
	local zname_zid
	local zid
	local test_record
	declare -g zone_id=''
	declare -g zone=''
	declare -g record_id=''
	declare -g record_ttl=''
	declare -g record_content=''
	is_quiet || echo -n "Searching zone ... " >&2
	
	for zname_zid in `call_cf_v4 GET /zones -- .result %"%s:%s$NL" ,name,id`
	do
		zone=${zname_zid%%:*}
		zone=${zone,,}
		zid=${zname_zid##*:}
		if [[ "$record_name" =~ ^((.*)\.|)$zone$ ]]
		then
			subdomain=${BASH_REMATCH[2]}
			zone_id=$zid
			break
		fi
	done
	[ -z "$zone_id" ] && { is_quiet || echo >&2; return 2; }
	is_quiet || echo -n "$zone, searching record ... " >&2
	
	rec_found=0
	oldIFS=$IFS
	IFS=$NL
	for test_record in `call_cf_v4 GET /zones/$zone_id/dns_records -- .result ,name,type,id,ttl,content`
	do
		IFS=$oldIFS
		set -- $test_record
		test_record_name=$1
		shift
		
		if [ "$test_record_name" = "$record_name" ]
		then
			test_record_type=$1
			shift
			test_record_id=$1
			shift
			test_record_ttl=$1
			shift
			test_record_content=$*
			
			if [ \( -z "$record_type" -o "$test_record_type" = "$record_type" \) -a \( -z "$record_oldcontent" -o "$test_record_content" = "$record_oldcontent" \) ]
			then
				let rec_found++
				[ $rec_found -gt 1 ] && { is_quiet || echo >&2; return 4; }
				
				record_type=$test_record_type
				record_id=$test_record_id
				record_ttl=$test_record_ttl
				record_content=$test_record_content
				if [ "$first_match" = 1 ]
				then
					# accept first matching record
					break
				fi
			fi
		fi
		IFS=$NL
	done
	IFS=$oldIFS
	
	is_quiet || echo "$record_id" >&2
	[ -z "$record_id" ] && return 3
	
	return 0
}

get_zone_id()
{
	zone_id=`call_cf_v4 GET /zones name="$1" -- .result ,id`
	if [ -z "$zone_id" ]
	then
		die "No such DNS zone found"
	fi
}




while [ -n "$1" ]
do
	case "$1" in
	-E)	shift
		CF_ACCOUNT=$1;;
	-T)	shift
		CF_TOKEN=$1;;
	-D|--debug)
		debug=1;;
	-d|--detail|--detailed|--details)
		details=1;;
	-q|--quiet)
		quiet=1;;
	-h|--help)
		die "$usage_text" 0
		;;
	--)	shift
		break;;
	-*)	false;;
	*)	break;;
	esac
	shift
done


if [ ! -f "$HOME/.cloudflare" ]
	then
		echo "No .cloudflare file."
	if [ -z "$CF_ACCOUNT" ]
	then
		die "No \$CF_ACCOUNT set.

	$usage_text"
	fi
	if [ -z "$CF_TOKEN" ]
	then
		die "No \$CF_TOKEN set.

	$usage_text"
	fi
else
	if is_debug; then echo "Found .cloudflare file."; fi
	source $HOME/.cloudflare
	if is_debug; then echo "Sourced CF_ACCOUNT: $CF_ACCOUNT CF_TOKEN: $CF_TOKEN"; fi
	
        if [ -z "$CF_ACCOUNT" ]
        then
                die "No \$CF_ACCOUNT set in config.

        $usage_text"
        fi
        if [ -z "$CF_TOKEN" ]
        then
                die "No \$CF_TOKEN set in config.

        $usage_text"
        fi
fi

if [ -z "$1" ]
then
	die "$usage_text" 1
fi




cmd1=$1
shift

case "$cmd1" in
list|show)
	cmd2=$1
	shift
	case "$cmd2" in
	zone|zones)
		call_cf_v4 GET /zones -- .result %"%s$TA%s$TA#%s$TA%s$TA%s$NL" ,name,status,id,original_name_servers,name_servers
		;;
	setting|settings)
		[ -z "$1" ] && die "Usage: cloudflare $cmd1 settings <zone>"
		if is_hex "$1"
		then
			zone_id=$1
		else
			get_zone_id "$1"
		fi
		if [ "$details" = 1 ]
		then
			fieldspec=,id,value,'?editable?"Editable"?""','?modified_on?<",, mod: $modified_on"?""'
		else
			fieldspec=,id,value,\"\",\"\"
		fi
		call_cf_v4 GET /zones/$zone_id/settings -- .result %"%-30s %s$TA%s%s$NL" "$fieldspec"
		;;
	record|records)
		[ -z "$1" ] && die "Usage: cloudflare $cmd1 records <zone>"
		if is_hex "$1"
		then
			zone_id=$1
		else
			get_zone_id "$1"
		fi
		call_cf_v4 GET /zones/$zone_id/dns_records -- .result %"%-20s %11s %-8s %s %s$TA; %s #%s$NL" \
			',@zone_name@name,?<$ttl==1?"auto"?ttl,type,||priority||data.priority||"",content,!!proxiable proxied locked,id'
		;;
	listing|listings|blocking|blockings)
		call_cf_v4 GET /user/firewall/access_rules/rules -- .result %"%s$TA%s$TA%s$TA# %s$NL" ',<$configuration["value"],mode,modified_on,notes'
		;;
	*)
		die "Parameters:
   zones, settings, records, listing"
		;;
	esac
	;;
	
add)
	cmd2=$1
	shift
	case "$cmd2" in
	record)
		[ $# -lt 4 ] && die \
"Usage: cloudflare add record <zone> <type> <name> <content> [ttl] [prio | proxied] [service] [protocol] [weight] [port]
	<zone>      domain zone to register the record in, see 'show zones' command
	<type>      one of: A, AAAA, CNAME, MX, NS, SRV, TXT, SPF, LOC
	<name>      subdomain name, or \"@\" to refer to the domain's root
	<content>   IP address for A, AAAA
		    FQDN for CNAME, MX, NS, SRV
                    any text for TXT, spf definition text for SPF
                    coordinates for LOC (see RFC 1876 section 3)
Additional Options
   	[ttl]       Time To Live, 1 = auto
   MX records:
   	[prio]      required only by MX and SRV records, enter \"10\" if unsure
   A or CNAME records:
	[proxied]   Proxied, true or false. For A or CNAME records only.
   SRV records:
	[service]   service name, eg. \"sip\"
	[protocol]  tcp, udp, tls
	[weight]    relative weight for records with the same priority
	[port]      layer-4 port number"
		
		zone=$1
		shift
		type=${1^^}
		shift 
		name=$1
		shift
		content=$1
		ttl=$2
		if [[ "$type" == "A" ]] || [[ "$type" == "CNAME" ]]; then
			proxied=$3
		elif [[ "$type" == "MX" ]] || [[ "$type" == "SRV" ]]; then
			prio=$3
		fi
		service=$4
		protocol=$5
		weight=$6
		port=$7
		
		[ -n "$proxied" ] || proxied=true
		[ -n "$ttl" ] || ttl=1
		[ -n "$prio" ] || prio=10
		if [[ $content =~ ^127.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]] && [[ "$type" == "A" ]]; then die "Can't proxy 127.0.0.0/8 using an A record"; fi
		get_zone_id "$zone"
		
		
		case "$type" in
		MX)
			call_cf_v4 POST /zones/$zone_id/dns_records "{\"type\":\"$type\",\"name\":\"$name\",\"content\":\"$content\",\"ttl\":$ttl,\"priority\":$prio}"
			;;
		LOC)
			locdata=''
			data_separated=1
			if [ -n "${content//[! ]/}" ]
			then
				data_separated=0
				set -- $content
			fi
			for key in lat_degrees lat_minutes lat_seconds lat_direction \
			  long_degrees long_minutes long_seconds long_direction \
			  altitude size precision_horz precision_vert
			do
				value=$1
				value=${value%m}
				locdata="$locdata${locdata:+,}\"$key\":\"$value\""
				shift
			done
			if [ $data_separated = 1 ]
			then
				ttl=${1:-1}
			fi
			call_cf_v4 POST /zones/$zone_id/dns_records "{\"type\":\"$type\",\"ttl\":$ttl,\"name\":\"$name\",\"data\":{$locdata}}"
			;;
		SRV)
			[ "${service:0:1}" = _ ] || service="_$service"
			[ "${protocol:0:1}" = _ ] || protocol="_$protocol"
			[ -n "$weight" ] || weight=1
			target=$content
			
			call_cf_v4 POST /zones/$zone_id/dns_records "{
				\"type\":\"$type\",
				\"ttl\":$ttl,
				\"data\":{
					\"service\":\"$service\",
					\"proto\":\"$protocol\",
					\"name\":\"$name\",
					\"priority\":$prio,
					\"weight\":$weight,
					\"port\":$port,
					\"target\":\"$target\"
					}
				}"
			;;
		TXT)
			call_cf_v4 POST /zones/$zone_id/dns_records "{\"type\":\"$type\",\"name\":\"$name\",\"content\":\"$content\",\"ttl\":$ttl}"
			;;
		A)
			call_cf_v4 POST /zones/$zone_id/dns_records "{\"type\":\"$type\",\"name\":\"$name\",\"content\":\"$content\",\"ttl\":$ttl,\"proxied\":$proxied}"
			;;
		CNAME)
			call_cf_v4 POST /zones/$zone_id/dns_records "{\"type\":\"$type\",\"name\":\"$name\",\"content\":\"$content\",\"ttl\":$ttl,\"proxied\":$proxied}"
			;;
		*)
			call_cf_v4 POST /zones/$zone_id/dns_records "{\"type\":\"$type\",\"name\":\"$name\",\"content\":\"$content\",\"ttl\":$ttl}"
			;;
		esac
		;;
		
	whitelist|blacklist|block|challenge)
		trg=$1
		trg_type=''
		shift
		notes=$*
		case "$cmd2" in
		  whitelist)	mode=whitelist;;
		  blacklist|block)	mode=block;;
		  challenge)	mode=challenge;;
		esac
		
		if expr "$trg" : '[0-9\.]\+$' >/dev/null
		then
			trg_type=ip
		elif expr "$trg" : '[0-9\.]\+/[0-9]\+$' >/dev/null
		then
			trg_type=ip_range
		elif expr "$trg" : '[A-Z]\+$' >/dev/null
		then
			trg_type=country
		fi
		[ -z "$trg" -o -z "$trg_type" ] && die "Usage: cloudflare add [<whitelist | blacklist | challenge>] [<IP | IP/mask | country_code>] [note]"
		
		call_cf_v4 POST /user/firewall/access_rules/rules mode=$mode configuration[target]="$trg_type" configuration[value]="$trg" notes="$notes"
		;;
		
	zone)
		if [ $# != 1 ]
		then
			die "Usage: cloudflare add zone <name>"
		fi
		call_cf_v4 POST /zones "{\"name\":\"$1\",\"jump_start\":true}" -- .result '&<"status: $status"'
		;;
		
	*)
		die "Parameters:
   zone, record, whitelist, blacklist, challenge"
	esac
	;;
	
delete)
	cmd2=$1
	shift
	case "$cmd2" in
	record)
		prm1=$1
		prm2=$2
		shift
		shift
		
		if [ ${#prm2} = 32 ] && is_hex "$prm2"
		then
			if [ -n "$1" ]
			then
				die "Unknown parameters: $@"
			fi
			if is_hex "$prm1"
			then
				zone_id=$prm1
			else
				get_zone_id "$prm1"
			fi
			record_id=$prm2
		
		else
			record_type=''
			first_match=0
			
			[ -z "$prm1" ] && die "Usage: cloudflare delete record [<record-name> [<record-type> | first] | [<zone-name>|<zone-id>] <record-id>]"
			
			if [ "$prm2" = first ]
			then
				first_match=1
			else
				record_type=${prm2^^}
			fi
			
			findout_record "$prm1" "$record_type" "$first_match"
			case $? in
			0)	true;;
			2)	die "No suitable DNS zone found for \`$prm1'";;
			3)	die "DNS record \`$prm1' not found";;
			4)	die "Ambiguous record spec: \`$prm1'";;
			*)	die "Internal error";;
			esac
		fi
		
		call_cf_v4 DELETE /zones/$zone_id/dns_records/$record_id
		;;
		
	listing)
		[ -z "$1" ] && die "Usage: cloudflare delete listing [<IP | IP range | country code | ID | note fragment>] [first]"
		call_cf_v4 GET /user/firewall/access_rules/rules -- .result ,id,configuration.value,notes |\
		while read ruleid trg notes
		do
			if [ "$ruleid" = "$1" -o "$trg" = "$1" ] || grep -qF "$1" <<<"$notes"
			then
				call_cf_v4 DELETE /user/firewall/access_rules/rules/$ruleid
				if [ "$2" = first ]
				then
					break
				fi
			fi
		done
		;;
		
	zone)
		if [ $# != 1 ]
		then
			die "Usage: cloudflare delete zone <name>"
		fi
		get_zone_id "$1"
		call_cf_v4 DELETE /zones/$zone_id
		;;
		
	*)
		die "Parameters:
   zone, record, listing"
	esac
	;;
	
change|set)
	cmd2=$1
	shift
	case "$cmd2" in
	zone)
		[ -z "$1" ] && die "Usage: cloudflare $cmd1 zone <zone> <setting> <value> [<setting> <value> [ ... ]]"
		[ -z "$2" ] && die "Settings:
   security_level [under_attack | high | medium | low | essentially_off]
   cache_level [aggressive | basic | simplified]
   rocket_loader [on | off | manual]
   minify <any variation of css, html, js delimited by comma>
   development_mode [on | off]
   mirage [on | off]
   ipv6 [on | off]
Other: see output of 'show zone' command"
		get_zone_id "$1"
		shift
		setting_items=''
		
		declare -A map
		map[sec_lvl]=security_level
		map[cache_lvl]=cache_level
		map[rocket_ldr]=rocket_loader
		map[async]=rocket_loader
		map[devmode]=development_mode
		map[dev_mode]=development_mode
		
		while [ -n "$1" ]
		do
			setting=$1
			shift
			[ -n "${map[$setting]}" ] && setting=${map[$setting]}
			setting_value=$1
			shift
			
			case "$setting" in 
			minify)
				css=off
				html=off
				js=off
				for s in ${setting_value//,/ }
				do
					case "$s" in
					css|html|js) eval $s=on;;
					*) die "E.g: cloudflare $cmd1 zone <zone> minify css,html,js"
					esac
				done
				setting_value="{\"css\":\"$css\",\"html\":\"$html\",\"js\":\"$js\"}"
			;;
			esac
			
			if [ "${setting_value:0:1}" != '{' ]
			then
				setting_value="\"$setting_value\""
			fi
			setting_items="$setting_items${setting_items:+,}{\"id\":\"$setting\",\"value\":$setting_value}"
		done
		
		call_cf_v4 PATCH /zones/$zone_id/settings "{\"items\":[$setting_items]}"
		;;
		
	record)
		str1="Usage: cloudflare $cmd1 record <name> [type <type> | first | oldcontent <content>] <setting> <value> [<setting> <value> [ ... ]]
You must enter \"type\" and the record type (A, MX, ...) when the record name is ambiguous, 
or enter \"first\" to modify the first matching record in the zone,
or enter \"oldcontent\" and the exact content of the record you want to modify if there are more records with the same name and type.
Settings:
  newname        Rename the record
  newtype        Change type
  content        See description in 'add record' command
  ttl            See description in 'add record' command
  proxied        Turn CF proxying on/off"
		[ -z "$1" ] && die "$str1"
		record_name=$1
		shift
		record_type=''
		first_match=0
		record_oldcontent=''
		
		while [ -n "$1" ]
		do
			case "$1" in
			first)	first_match=1;;
			type)	shift; record_type=${1^^};;
			oldcontent)	shift; record_oldcontent=$1;;
			*)		break;;
			esac
			shift
		done
		
		if [ -z "$1" ]
		then
			die "$str1"
	   	fi
		
		findout_record "$record_name" "$record_type" "$first_match" "$record_oldcontent"
		e=$?
		case $e in
		0)	true;;
		2)	die "No suitable DNS zone found for \`$record_name'";;
		3)	is_quiet && die || die "DNS record \`$record_name' not found";;
		4)	die "Ambiguous record name: \`$record_name'";;
		*)	die "Internal error";;
		esac
		
		record_content_esc=${record_content//\"/\\\"}
		old_data="\"name\":\"$record_name\",\"type\":\"$record_type\",\"ttl\":$record_ttl,\"content\":\"$record_content_esc\""
		new_data=''
		while [ -n "$1" ]
		do
			setting=$1
			shift
			value=$1
			shift
			
			[ "$setting" = service_mode ] && setting=proxied
			[ "$setting" = newtype -o "$setting" = new_type ] && setting=type
			[ "$setting" = newname -o "$setting" = new_name ] && setting=name
			[ "$setting" = newcontent ] && setting=content
			if [ "$setting" = proxied ]
			then
				value=${value,,}
				[ "$value" = on -o "$value" = 1 ] && value=true
				[ "$value" = off -o "$value" = 0 ] && value=false
			fi
			[ "$setting" = type ] && value=${value^^}
			
			if [ "$setting" != content ] && ( expr "$value" : '[0-9]\+$' >/dev/null || expr "$value" : '[0-9]\+\.[0-9]\+$' >/dev/null || [ "$value" = true -o "$value" = false ] )
			then
				value_escq=$value
			else
				value_escq=\"${value//\"/\\\"}\"
			fi
			new_data="$new_data${new_data:+,}\"$setting\":$value_escq"
		done
		
		call_cf_v4 PUT /zones/$zone_id/dns_records/$record_id "{$old_data,$new_data}"
		;;
		
	*)
		die "Parameters:
   zone, record"
	esac
	;;
	
clear)
	case "$1" in
	cache)
		shift
		[ -z "$1" ] && die "Usage: cloudflare clear cache <zone>"
		get_zone_id "$1"
		call_cf_v4 DELETE /zones/$zone_id/purge_cache '{"purge_everything":true}'
		;;
	*)
		die "Parameters:
   cache"
		;;
	esac
	;;
	
check)
	case "$1" in
	zone)
		shift
		[ -z "$1" ] && die "Usage: cloudflare check zone <zone>"
		get_zone_id "$1"
		call_cf_v4 PUT /zones/$zone_id/activation_check
		;;
	*)
		die "Parameters:
   zone"
		;;
	esac
	;;

invalidate)
	if [ -n "$1" ]
	then
		urls=''
		zone_id=''
		for url in "$@"
		do
			urls="${urls:+$urls,}\"$url\""
			if [ -z "$zone_id" ]
			then
				if [[ "$url" =~ ^([^:]+:)?/*([^:/]+) ]]
				then
					re_grps=${#BASH_REMATCH[@]}
					domain=${BASH_REMATCH[re_grps-1]}
					while true
					do
						zone_id=`get_zone_id "$domain" 2>/dev/null; echo "$zone_id"`
						if [ -n "$zone_id" ]
						then
							break
						fi
						parent=${domain#*.}
						if [ "$parent" = "$domain" ]
						then
							break
						fi
						domain=$parent
					done
				fi
			fi
		done
		if [ -z "$zone_id" ]
		then
			die "Zone name could not be figured out."
		fi
		call_cf_v4 DELETE /zones/$zone_id/purge_cache "{\"files\":[$urls]}"
	else
		die "Usage: cloudflare invalidate <url-1> [url-2 [url-3 [...]]]"
	fi
	;;
	
json)
	json_decode "$@"
	;;
	
*|help)
	die "Commands:
   show, add, delete, change, clear, invalidate, check

show        zones, settings, records, listing
add         zone, record, whitelist, blacklist, challenge
delete      zone, record, listing
change      zone, record
clear       cache

Examples:

$ cloudflare show settings example.net
advanced_ddos                  off
always_online                  on
automatic_https_rewrites       off
...

$ cloudflare show records example.net
www     auto CNAME     example.net.       ; proxiable,proxied #IDSTRING
@       auto A         198.51.100.1       ; proxiable,proxied #IDSTRING
*       3600 A         198.51.100.2       ;  #IDSTRING
...

$ cloudflare show records example.net
www     auto CNAME     example.net.       ; proxiable,proxied #IDSTRING
@       auto A         198.51.100.1       ; proxiable,proxied #IDSTRING
*       3600 A         198.51.100.2       ;  #IDSTRING
...

"
	;;
esac

