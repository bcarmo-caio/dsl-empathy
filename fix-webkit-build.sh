#!/bin/bash

if [[ "$#" != "2" ]]; then
	echo something.la make-n_file
	exit 1
fi

#exit on first error
set -e

MAKE_OUT_FILE=$2 #make -n > make.out
LA_TO_BUILD=$1   #something.la

cat $MAKE_OUT_FILE | grep "echo \"  CXXLD \" $LA_TO_BUILD;" | \
	 sed -r "s/.*-o $LA_TO_BUILD//" | \
	 sed -r "s/ /\n/g" | \
	 egrep -i [a-z] > .tmp
		 
IFS="
"

ABORT=false
for file in $(cat .tmp); do
	test -e ../$file || (ABORT=true && echo "Error. ../$file should be found.")
done

if $ABORT; then
	echo "Aborting..."
	exit 1
fi

# $file is something like this
# Source/WebCore/Modules/geolocation/libWebCore_la-Geolocation.lo
echo "Copying necessary files..."
for file in $(cat .tmp); do
	lo_obj=$(echo $file | sed -r "s/.*\///")
	path=$(echo $file | sed -r "s/$lo_obj//")
	o_obj=$(echo $lo_obj | sed -r "s/\.lo$/\.o/")
	#TODO melhorar o jeito de ver se tem aquivos repetidos. Se tiver, fudeu
	cp -i ../$file .
	#fixing line
	#pic_object='.libs/libWebCore_la-PointLightSource.o'
	#in new copied file
	sed --in-place -r "s|^pic_object.*|pic_object='../$path.libs/$o_obj'|" \
		$lo_obj
done

if cat .tmp | egrep -v *.lo$; then
	echo tem xereta aqui
	exit 1
fi

rm -f .tmp

MAKE_BROKEN_CMD_LINE=$(cat $MAKE_OUT_FILE | grep "\-o $LA_TO_BUILD" | \
	sed -r "s/-o $LA_TO_BUILD.*//" | \
	sed -r "s/^echo \"  CXXLD \" $LA_TO_BUILD\;//")

USED_TOOL=$(echo $MAKE_BROKEN_CMD_LINE | \
	sed -r "s/( |	).*//" | \
	sed -r "s/^\.\///")

OPTIONS=$(echo $MAKE_BROKEN_CMD_LINE | \
	sed -r "s|^\.\/$USED_TOOL||")

#TODO arrumar isso. sempre entra no if
#if test -x ../$USED_TOOL; then
#	echo We need $USED_TOOL. But I could not find it.
#	echo Aborting...
#	exit 1
#fi


#../$USED_TOOL $OPTIONS -o $LA_TO_BUILD *.lo

LIB_TO_BUILD=$(echo $LA_TO_BUILD | sed -r "s/\.la$/\.a/")

#TODO arrumar isso. O certo e':  $USED_TOOL $OPTIONS *.lo
echo Building $LA_TO_BUILD and $LIB_TO_BUILD
../doltlibtool  --silent --tag=CXX   --mode=link \
	g++ -fvisibility-inlines-hidden -fno-rtti -Wno-c++0x-compat -O2\
	-o libWebCore.la *.lo

cd ..
cp .zuado/.libs/$LIB_TO_BUILD .libs/
cp .zuado/$LA_TO_BUILD .
cd .libs
ln -s ../$LA_TO_BUILD .

echo Done building $LA_TO_BUILD and $LIB_TO_BUILD

exit 0
