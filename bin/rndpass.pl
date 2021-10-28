#!/usr/bin/perl

use List::Util qw/shuffle/;

# Usage: addwww <length> <difficulty>
# Example: addwww 10 1

#$def_diff = $ARGV[0];
#$def_length = $ARGV[1];

$def_length = "10";
$def_diff = "2";

$password1 = randomPassword($def_length);
$password2 = randomWord() . randomNumber(2) . randomWord() . randomNumber(4);
$password3 = randomWord() . randomNumber(4);
$password4 = randomNumber(1) . randomWord() . randomNumber(1) . randomWord() . randomNumber(2);
$password5 = randomPassword(25);
$password6 = randomWord() . randomNumber(1) . randomWord();

print "Content-type: text/html\n\n";

print <<ENDHTML;
<html><head>
<title>CFRI - Random Password Generator</title>
</head>
<body> 
<table>
 <tr>
  <td width="400"><b>Completely Random 10 Char</b></td>
  <td>$password1</td>
 </tr>
  <tr>
    <td width="400"><b>Completely Random 25 Char</b></td>
    <td>$password5</td>
 </tr>
  <tr>
    <td><b>Word - Number(1) - Word </b></td>
   <td>$password6</td>
 </tr>      
 <tr>
  <td><b>Word - Number(2) - Word - Numbers(4)</b></td>
  <td>$password2</td>
 </tr>
 <tr>
  <td><b>Word - Number(4)</b></td>
  <td>$password3</td>
 </tr>
 <tr>
  <td><b>Number(1) - Word - Number(1) - Word - Number(2)</b></td>
  <td>$password4</td>
</table>
       
<br>   
</body>
</html>
ENDHTML

# functions

sub randomWord {

my $wordlist = '/usr/share/dict/words';

my $length = 4;   
my $numwords = 10;

my @words;

open WORDS, '<', $wordlist or die "Cannot open $wordlist:$!";

while (my $word = <WORDS>) {
    chomp($word);
    push @words, $word if (length($word) == $length);
}

close WORDS;

my @shuffled_words = shuffle(@words);

return $shuffled_words[1];
 
}

sub randomPassword {
my $password;
my $_rand;

my $password_length = $_[0];
        if (!$password_length) {
                $password_length = 10;
        }

my @chars = split(" ","a b c d e f g h i j k l m n o p q r s t u v w x y z ! # ^ * + A B C D E F G H I J K L M N O P Q R S T U V W X Y Z 0 1 2 3 4 5 6 7 8 9");

srand;

for (my $i=0; $i <= $password_length ;$i++) {
        $_rand = int(rand 67);
        $password .= $chars[$_rand];
}
return $password;
}

sub randomNumber {
my $password;
my $_rand;

my $password_length = $_[0];
        if (!$password_length) {
                $password_length = 1;
        }

my @chars = split(" ","0 1 2 3 4 5 6 7 8 9");

srand;

for (my $i=1; $i <= $password_length ;$i++) {
        $_rand = int(rand 10);  
        $password .= $chars[$_rand]; 
        }
return $password;
}
