# --
# replace commands
#
# Example help: help_template[test]='Generate phpinfo() file'
#
# --
_debug " -- Loading ${(%):-%N}"

# What help file is this?
help_files[aws]="AWS Commands and scripts"

# - Init help array
typeset -gA help_aws

_debug " -- Loading ${(%):-%N}"

# -- aws-cli
help_aws[aws-cli]="If installed, aws-cli is available, if not type software aws-cli"

# -- aws-list-instances
help_aws[aws-list-instances]='Print instances with connected aws profile'
aws-list-instances () {
	aws ec2 describe-instances \
	--query "Reservations[*].Instances[*].[Tags[? 
  	Key=='Name'].Value|[0], InstanceId, InstanceType, State.Name, PublicIpAddress ]" \
	--output table
}