string="
पुष्प विहार"
for word in $string; do trans=`varnamc -s mr -r $word`; var1=`echo $trans`; echo $var1; done
