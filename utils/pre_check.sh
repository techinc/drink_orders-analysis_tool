#!/bin/bash


echo "* Checking source material integrity"

# check to see if all source material has a working symlink
echo -n "** Checking source file links           :" 
for i in `ls ../order_info/source_material/order*`
do
	if [[ -L $i ]] && [[ -e $i ]]
	then
		echo -n .
	else
		export error="File is not a (working) symlink: order_info/source_material/$i\n"$error
	fi
done

if [[ -z $error ]]
then
	echo "OK"
else
	echo "FAIL"
	echo -e $error
	export glob_error="SOURCE_SYMLINK_CHECK\n"$glob_error
fi



error=""
# check if the correct files are present
echo -n "** Checking CSV for each SOURCE         :"
for i in `cd ../order_info/source_material/; ls order*`
do
	ls ../order_info/csv/$i > /dev/null 2>&1
	rc=$?
	if [[ $rc != 0 ]]
	then
		export error="Missing file: order_info/csv/$i\n"$error
	fi
	echo -n .
done

if [[ -z $error ]]
then
	echo "OK"
else
	echo "FAIL"
	echo -e $error
	export glob_error="SOURCE->CSV check\n"$glob_error
fi

error=""
echo -n "** Checking SOURCE for each CSV         :"
for i in `cd ../order_info/csv/; ls order*`
do
	ls ../order_info/source_material/$i > /dev/null 2>&1
	rc=$?
	if [[ $rc != 0 ]]
	then
		export error="Missing file: order_info/source_material/$i\n"$error
	fi
	echo -n .
done

if [[ -z $error ]]
then
	echo "OK"
else
	echo "FAIL"
	echo -e $error
	export glob_error="CSV->SOURCE check\n"$glob_error
fi

if [[ ! -z $glob_error ]]
then
	echo "**** Not continuing with further checks due to errors!"
	echo "exiting"
	exit 1
else
	echo "**** All source files seem sane"
fi

error=""
echo "* Checking summary file"
echo -n "** Summary entry for each CSV           :"
for i in `cd ../order_info/csv; ls order*`
do
	grep $i ../order_info/order-summary > /dev/null 2>&1
	rc=$?
	if [[ $rc != 0 ]]
	then
		export error="Entry missing from summary: $i\n"$error
	fi
	echo -n .
done

if [[ -z $error ]]
then
	echo "OK"
else
	echo "FAIL"
	echo -e $error
	export glob_error="CSV->SUMMARY\n"$glob_error
fi


error=""
echo -n "** CSV file for each summary file entry :"
for i in `cut  -d "|" -f1 ../order_info/order-summary`
do
	ls ../order_info/csv/$i > /dev/null 2>&1
	rc=$?
	if [[ $rc != 0 ]]
	then
		export error="CSV file missing for summary entry: order_info/csv/$i\n"$error
	fi
	echo -n .
done

if [[ -z $error ]]
then
	echo "OK"
else
	echo "FAIL"
	echo -e $error
	export glob_error="SUMMARY->CSV\n"$glob_error
fi

if [[ ! -z $glob_error ]]
then
	echo "Error encountered"
	echo -e $glob_error
	echo exiting
	exit 1
fi
