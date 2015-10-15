#!/usr/bin/env bash
# SmartOS memory allocation display | 010415 | tamas@gerczei.eu
# echo "tty -s && $0.sh" >> ~/.bashrc

# sanity check
if [[ ! $(uname -v) =~ ^joyent_[0-9]{8}T[0-9]{6}Z ]]
        then
		# proceeding would make no sense
                echo "This is not a SmartOS system - bailing out."
                exit 1
fi

function count () {
	# sum memory allocation for VMs in a given state
	while read ram state
		do
			if [ ${state:-none} == "$1" ]
		 		then
					total=$((${total:-0}+$ram))
			fi
		done
	echo ${total:-0}
}

# obtain status
output=$(vmadm lookup -jo max_physical_memory,state | json -a max_physical_memory state)

# enumerate allocation
r_amount=$(count running <<< "$output")
s_amount=$(count stopped <<< "$output")

# obtain available memory amount
totalram=$(prtconf -m)

# evaluate free memory
freeram=$((totalram-$r_amount))

# set dynamic output padding
digits=$(wc -c <<< $totalram)

# print-out
printf "%${digits}dM allocated to running VMs\n%${digits}dM configured for stopped VMs\n" $r_amount $s_amount

if [ $freeram -lt 0 ]
        then
                what="overcommitted"
                freeram=$(($freeram * -1))
                printf "%${digits}dM short of being able to run all VMs, " $(($freeram + $s_amount))
fi

printf "%${digits}dM %s\n" $freeram ${what:-free}
