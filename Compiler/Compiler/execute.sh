read fname1
read out
unlink func.txt
./out.exe $fname1 
if [ "$out" = 1 ]; then g++ output.cpp
else 
    g++ -std=c++11 -g -o a optimizer.cpp
fi

./a.exe