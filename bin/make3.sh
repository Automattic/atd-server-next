java -Xmx1024M -jar sleep.jar gen3.sl corpus2 homophones.txt ho_test_gutenberg_context.txt
java -Xmx1024M -jar sleep.jar gen2.sl corpus2 homophones.txt ho_train_gutenberg_context.txt
java -Xmx1024M -jar sleep.jar gen3.sl /home/raffi/spell/corpus homophones.txt ho_test_wp_context.txt
