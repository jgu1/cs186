#!/bin/bash

INPUT_BOOK=$1
SEP_BK_DIR="separatedBooks" 
EBOOK_CSV_HEAD_LINE="title,author,release_date,ebook_id,language,body\r"
#EBOOK_CSV_FILE="../my-hw1ebook.csv"
EBOOK_CSV_FILE="../ebook.csv"
TOKENS_CSV_HEAD_LINE="ebook_id,token\r"
TOKENS_CSV_FILE="../tokens.csv"
COPY_TOKENS_CSV_FILE="../copy-tokens.csv"
TOKEN_COUNTS_CSV_HEAD_LINE="token,count\r"
TOKEN_COUNTS_FILE="../token_counts.csv"
POP_NAMES_TXT="../popular_names.txt"
NAME_COUNTS_CSV_HEAD_LINE="token,count\r"
NAME_COUNTS_CSV_FILE="../name_counts.csv"
rm -rf $SEP_BK_DIR
mkdir -p $SEP_BK_DIR
#awk '{print $0 > "separatedBooks/book-"NR".txt"}' RS='[\*]+ END OF THE PROJECT GUTENBERG [^\*]+[\*]+' $INPUT_BOOK 
awk '{print $0 > "separatedBooks/book-"NR".txt";close("separatedBooks/book-"NR".txt")}' RS='[\*]+ END OF THE PROJECT GUTENBERG [^\*]+[\*]+' $INPUT_BOOK 


cd $SEP_BK_DIR
mkdir -p keywords
mkdir -p body
mkdir -p beforeStart



for book in *.txt
do
#   generate the keyword-files and body-files
#   sed -i 's/\r//g' $book    #remove carriage return
    awk -v bookname="beforeStart/$book" 'NR==1{print $0 > bookname; close(Infile); close(bookname)}' Infile="$book" RS='START OF THE PROJECT GUTENBERG [^\*]+[\*]+' $book 
    Title=$(sed -n 's/^Title: \(.*\)$/\1/p' "beforeStart/$book")
    Title=$(echo "$Title" | sed 's/\"/\"\"/g')				#replace double quote with "dobule" double quote
    if [[ "$Title" == *','* ]] || [[ "$Title" == *"\""* ]]; then	#check if Title contains star or quote
        Title=$(echo "$Title" | sed -e 's/^/\"/' -e 's/$/\"/')
    fi
    echo "$Title" > keywords/$book
    
    Author=$(sed -n 's/^Author: \(.*\)$/\1/p'  "beforeStart/$book")
    Author=$(echo "$Author" | sed 's/^\s*//g' )				#trim leading spaces
    if [[ "$Author" == *','* ]]; then
        Author=$(echo "$Author" | sed -e 's/^/\"/' -e 's/$/\"/')
    fi
    if [ -z "$Author" ];then
        Author="null"
    fi

    echo "$Author" >> keywords/$book
  
    ReleaseDate=$(sed -nr 's/^Release Date: ([A-Za-z0-9, ]*)\[(EBook|Etext|eBook) #[0-9]+.*$/"\1"/p' "beforeStart/$book")
    ReleaseDate=$(echo "$ReleaseDate" | sed 's/\s*\"$/\"/g')		#trim the trailing spaces before quote    
    #ReleaseDate=$(echo "$ReleaseDate" | sed 's/^\"\([a-zA-Z]* \d*\)\"/\1/')
    ReleaseDate=$(echo "$ReleaseDate" | sed -r 's/^\"([a-zA-Z]+\s[0-9]+)\"/\1/')
    echo "$ReleaseDate" >> keywords/$book
 
#   ReleaseDate=$(sed -n 's/^Release Date: \([A-Za-z0-9, ]*\)\[EBook #\([0-9]*\).*$/\1/p'  "beforeStart/$book")
#    ReleaseDate=$(echo "$ReleaseDate" | sed 's/\s*$//g')		#trim the trailing spaces before quote    
#    if [[ "$ReleaseDate" == *','* ]]; then
#        Author=$(echo "$ReleaseDate" | sed -e 's/^/\"/' -e 's/$/\"/')
#    fi
#    echo "$ReleaseDate" >> keywords/$book
    
    BookNo=$(sed -nr 's/^Release Date: [A-Za-z0-9, ]*\[(EBook|Etext|eBook) #([0-9]+).*$/\2/p' "beforeStart/$book")
    echo "$BookNo" >> keywords/$book
  
    Language=$(sed -n 's/^Language: \(.*\)$/\1/p' "beforeStart/$book")
    echo "$Language" >> keywords/$book
     
    cat keywords/$book | tr "\\n" "," > keywords/"key-words-$book"
    sed -i 's/\r//g' keywords/"key-words-$book"    			#remove carriage return
    awk -v bookname="body/body-$book" 'NR==2{print $0 > bookname;close(Infile)}' Infile="$book" RS='START OF THE PROJECT GUTENBERG [^\*]+[\*]+' $book 
    sed -i 's/\"/\"\"/g' body/body-$book	#replace double quote with two double quote
#   generate the keyword-files and body-files

#   combine keyword-file and body-file into a book
    rm $book

    cat keywords/key-words-$book > $book
    sed -i '1s/$/\"/' $book
    cat body/body-$book >> $book
    sed -i "2 d" $book
    sed -i "$ d" $book			#cut off the very last line in a book
    sed -i "$ d" $book			#cut off the very last line in a book
    echo -e "\"\r" >> $book             #append a quote sign to the end of file  
#   combine keyword-file and body-file into a book
done

#concatenate individual books into a ebook.csv file
echo -e "$EBOOK_CSV_HEAD_LINE" > $EBOOK_CSV_FILE		#add title line
for book in *.txt
do
    cat $book >> $EBOOK_CSV_FILE
done 
sed -i "$ d" $EBOOK_CSV_FILE		#strip the very last line(a quote and a carriage return)
#concatenate individual books into a ebook.csv file

#separate book body to track tokens
echo -e "$TOKENS_CSV_HEAD_LINE" > $TOKENS_CSV_FILE
for book in *.txt
do
    book_id=$(sed -n 4p keywords/$book)
    awk '$0!=""{print bookid,tolower($0)"\r" >> of;close(Infile)}' Infile="body/body-$book"  bookid="$book_id" of="$TOKENS_CSV_FILE" RS="[^a-zA-Z]" OFS=',' body/body-$book
done
#separate book body to track tokens

#count word occurence    
    echo -e "$TOKEN_COUNTS_CSV_HEAD_LINE" > $TOKEN_COUNTS_FILE
    sed  's/\r//g' "$TOKENS_CSV_FILE" > $COPY_TOKENS_CSV_FILE    			#remove carriage return
    cat  $COPY_TOKENS_CSV_FILE | awk 'NR!=1{print $2;close("cat  $COPY_TOKENS_CSV_FILE")}' FS=',' | sort | uniq -c | awk '{print $2, $1"\r"}' OFS=',' >> $TOKEN_COUNTS_FILE

#count word occurence
#count popular names
echo -e "$NAME_COUNTS_CSV_HEAD_LINE" > $NAME_COUNTS_CSV_FILE
while read NAME
do
    NAME=$(echo "$NAME" | awk '{print tolower($0);close(echo "$NAME")}')
    nameAndCount=$(sed -n "s/^\($NAME,\d*\)/\1/p" $TOKEN_COUNTS_FILE)
    
    if [ -n "$nameAndCount" ];then
        echo "$nameAndCount" >> $NAME_COUNTS_CSV_FILE
    fi
done < $POP_NAMES_TXT
#count popular names
exit 0
