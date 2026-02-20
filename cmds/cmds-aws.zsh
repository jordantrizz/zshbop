# =============================================================================
# -- AWS
# =============================================================================
_debug " -- Loading ${(%):-%N}"
help_files[aws]="AWS Commands and scripts"
typeset -gA help_aws


# --------------------------------------------------
# -- aws-cli
# --------------------------------------------------
help_aws[aws-cli]="If installed, aws-cli is available, if not type software aws-cli"

# --------------------------------------------------
# -- aws-list-instances
# --------------------------------------------------
help_aws[aws-list-instances]='Print instances with connected aws profile'
aws-list-instances () {
	aws ec2 describe-instances \
	--query "Reservations[*].Instances[*].[Tags[? 
  	Key=='Name'].Value|[0], InstanceId, InstanceType, State.Name, PublicIpAddress ]" \
	--output table
}

# --------------------------------------------------
# -- aws-list-profiles
# --------------------------------------------------
help_aws[aws-list-profiles]='Print all configured aws profiles'
function aws-list-profiles () {
    # Get a list of all configured AWS profiles
    local profiles=($(aws configure list-profiles))

    # Iterate over each profile
    for profile in $profiles; do
        echo "Profile: $profile"

        # Set AWS_PROFILE to use the current profile
        export AWS_PROFILE=$profile

        # Get organization details
        local org_details=$(aws organizations describe-organization --output json 2>/dev/null)

        if [[ $? -eq 0 ]]; then
            local org_id=$(echo $org_details | jq -r '.Organization.MasterAccountId')
			local org_email=$(echo $org_details | jq -r '.Organization.MasterAccountEmail')
            local org_name=$(echo $org_details | jq -r '.Organization.MasterAccountName')
			echo "  Organization ID: $org_id"
            echo "  Organization Email: $org_email"
            echo "  Organization Name: $org_name"
        else
            echo "  Unable to fetch organization details"
        fi
    done

    # Unset AWS_PROFILE to avoid unintended consequences
    unset AWS_PROFILE
}