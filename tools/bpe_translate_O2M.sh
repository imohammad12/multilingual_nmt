#!/usr/bin/env bash

TF=$(printf "%q\n" "$(pwd)")
export PATH=$TF/bin:$PATH

BPE_OPS=32000
# Change this for bigger BPE Models

GPUARG=0

L1=$1
L2=$2
L3=$3
model=$4
prefix=$5

DATA_L1=${TF}"/data/${L1}_${L2}"
DATA_L2=${TF}"/data/${L1}_${L3}"
NAME="run_${prefix}_${L1}_${L2}-${L3}"
OUT="temp/$NAME"

TEST_SRC_L1=$DATA_L1/test.${L1}
TEST_TGT_L1=$DATA_L1/test.${L2}

TEST_SRC_L2=$DATA_L2/test.${L1}
TEST_TGT_L2=$DATA_L2/test.${L3}

# Apply BPE Coding to the languages
apply_bpe -c $OUT/data/bpe-codes.${BPE_OPS} < ${TEST_SRC_L1} > ${OUT}/data/test_l1.src
apply_bpe -c $OUT/data/bpe-codes.${BPE_OPS} < ${TEST_SRC_L2} > ${OUT}/data/test_l2.src

# Translate Language 1
python translate.py -i $OUT/data --data processed --batchsize 28 --beam_size 5 \
--best_model_file $OUT/models/model_best_$NAME.ckpt --src $OUT/data/test_l1.src \
--gpu $GPUARG --output $OUT/test/test_l1.out --model ${model} --max_decode_len 70

mv $OUT/test/test_l1.out $OUT/test/test_l1.out.bpe
cat $OUT/test/test_l1.out.bpe | sed -E 's/(@@ )|(@@ ?$)//g' > $OUT/test/test_l1.out
# perl tools/multi-bleu.perl $TEST_TGT_L1 < $OUT/test/test_l1.out > $OUT/test/test_l1.tc.bleu
t2t-bleu --translation=$OUT/test/test_l1.out --reference=$TEST_TGT_L1 > $OUT/test/test_l1.t2t-bleu

# EMA
mv $OUT/test/test_l1.out.ema $OUT/test/test_l1.out.ema.bpe
cat $OUT/test/test_l1.out.ema.bpe | sed -E 's/(@@ )|(@@ ?$)//g' > $OUT/test/test_l1.out.ema
# perl tools/multi-bleu.perl $TEST_TGT_L1 < $OUT/test/test_l1.out.ema > $OUT/test/test_l1.tc.bleu.ema
t2t-bleu --translation=$OUT/test/test_l1.out.ema --reference=$TEST_TGT_L1 > $OUT/test/test_l1.t2t-bleu.ema


# Translate Language 2
python translate.py -i $OUT/data --data processed --batchsize 28 --beam_size 5 \
--best_model_file $OUT/models/model_best_$NAME.ckpt --src $OUT/data/test_l2.src \
--gpu $GPUARG --output $OUT/test/test_l2.out --model ${model} --max_decode_len 70

mv $OUT/test/test_l2.out $OUT/test/test_l2.out.bpe
cat $OUT/test/test_l2.out.bpe | sed -E 's/(@@ )|(@@ ?$)//g' > $OUT/test/test_l2.out
# perl tools/multi-bleu.perl $TEST_TGT_L2 < $OUT/test/test_l2.out > $OUT/test/test_l2.tc.bleu
t2t-bleu --translation=$OUT/test/test_l2.out --reference=$TEST_TGT_L2 > $OUT/test/test_l2.t2t-bleu

# EMA
mv $OUT/test/test_l2.out.ema $OUT/test/test_l2.out.ema.bpe
cat $OUT/test/test_l2.out.ema.bpe | sed -E 's/(@@ )|(@@ ?$)//g' > $OUT/test/test_l2.out.ema
# perl tools/multi-bleu.perl $TEST_TGT_L2 < $OUT/test/test_l2.out.ema > $OUT/test/test_l2.tc.bleu.ema
t2t-bleu --translation=$OUT/test/test_l2.out.ema --reference=$TEST_TGT_L2 > $OUT/test/test_l2.t2t-bleu.ema
