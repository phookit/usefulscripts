#!/bin/bash

CURR_WD=`pwd`
CSCOPE_CMD="$HOME/local/bin/cscope -b -q"

# ensure useview has been used
[[ -z ${CLEARCASE_ROOT} ]] && { echo "Not in a view"; exit -1; }

echo "IN VIEW: ${CLEARCASE_ROOT}"

CSCOPE_DB_ROOT="$HOME/cscope"
CSCOPE_VIEW_ROOT="${CSCOPE_DB_ROOT}/v2/${CLEARCASE_ROOT}"
CSCOPE_FILES_OUT="${CSCOPE_DB_ROOT}/v2/${CLEARCASE_ROOT}/cscope.files"
TMP_CSCOPE_DIR="/tmp/${CLEARCASE_ROOT}"
TMP_CSCOPE_FILE=$TMP_CSCOPE_DIR/cscope.tmp

[[ -f ${TMP_CSCOPE_FILE} ]] && rm $TMP_CSCOPE_FILE
[[ ! -d ${TMP_CSCOPE_DIR} ]] && mkdir -p ${TMP_CSCOPE_DIR}

CODE_DIR_LIST="/path/one \
               /another/path"

IGNORE_DIRS="/ignore/me \
             /also/ignore/me"

PRUNE_INSTR=
for d in $IGNORE_DIRS
do
  if [ -z "$PRUNE_INSTR" ]; then
    PRUNE_INSTR="-wholename $d -prune"
  else
    PRUNE_INSTR="$PRUNE_INSTR -o -wholename $d -prune"
  fi
done


for dir in $CODE_DIR_LIST
do
  echo "Indexing $dir"
  #find $dir \( ! -type l \) \
  #  \( \
  #    -not -iwholename '*id_whatFile*' -a \
  #    -not -iwholename '*.idl.*' \
  #  \) \
  #  \( $PRUNE_INSTR -o -iname '*.h' -o -iname '*.C' -o -iname '*.cpp' -o -iname '*.i' \) \( -type f \) >> ${TMP_CSCOPE_FILE}
  find $dir \( ! -type l \) \
    \( \
      -not -iwholename '*id_whatFile*' -a \
      -not -iwholename '*.idl.*' \
    \) \
    \( \
      $PRUNE_INSTR -o \
      -iname '*.h' -o \
      -iname '*.C' -o \
      -iname '*.cpp' -o \
      -iname '*.i' \
    \) \
    \( -type f \) >> ${TMP_CSCOPE_FILE}
done

# make sure the cscope local view directory exists
[[ ! -d ${CSCOPE_VIEW_ROOT} ]] && mkdir -p ${CSCOPE_VIEW_ROOT}

mv ${TMP_CSCOPE_FILE} ${CSCOPE_FILES_OUT}

# Generate the cscope database
echo "Creating cscope database from ${CSCOPE_FILES_OUT}"
cd ${CSCOPE_VIEW_ROOT}
${CSCOPE_CMD} 

# change back to orig dir
cd ${CURR_WD}

