#include<bits/stdc++.h>
#include<cstring>
using namespace std;

map<string,int>values;
vector<string>final_list;

void print_icg(vector<string>Line_List){
    int n = Line_List.size();
    cout<<"Printing the read ICG file : \n";
    for(int i=0;i<n;i++){  
        cout<<Line_List[i]<<endl;
    }
}

vector<string> token_maker(string line) {
    vector <string> tokens;
    stringstream check1(line);
    string imd;
      
    // Tokenizing w.r.t. space ' '
    while(getline(check1, imd, ' ')) {
        int slen = imd.length();
        if(imd[slen - 1] == ';') {
            tokens.push_back(imd.substr(0,slen-1));
        }
        else{
            tokens.push_back(imd);
        }
    }
    // (res,assg,arg1,op,arg2) 
    return tokens;
}

bool is_digit(string arg) {
    int len = arg.length();
    for(int i=0;i<len;i++) {
        if(arg[i]>='0' && arg[i]<='9') {
            continue ;
        }
        else {
            return false;
        }
    }
    return true;
}

int evaluate(int arg1, string op, int arg2) {
    int answer = 0;
    int d1 = arg1;
    int d2 = arg2;
    if(op == "+" || op=="++")
        answer = d1 + d2;
    else if(op == "-" || op=="--")
        answer = d1 - d2;
    else if(op  == "*")
        answer = d1 * d2;
    else if(op  == "/")
        answer = d1 / d2;
    else if(op  == "%")
        answer = d1 % d2;
    else if(op  == "**")
        answer = pow(d1, d2);
    else if(op  == "<")
        answer = d1 < d2;
    else if(op  == "<=")
        answer = d1 <= d2;
    else if(op  == ">")
        answer = d1 > d2;
    else if(op  == ">=")
        answer = d1 >= d2;
    else if(op  == "==")
        answer = d1 == d2;
    else if(op  == "!=")
        answer = d1 != d2;
    else 
        answer = INT_MAX;
        // case "&&":
        //     break;
        // case "||":
        //     break;
    return answer;
}

int to_int(string str){
    stringstream geek1(str);
    int x = 0;
    geek1 >> x;
    return x;      
}

string to_str(int num){
    ostringstream str1;
    str1 << num;
    string geek = str1.str();
    return geek;
}

void folding(vector<string>Line_List){

    int total_lines = Line_List.size();
    int line_num = 0;
    bool is_loop = false;
    string num_loop_curr = "";
    string num_loop_next = "";
    bool is_if = false;
    string num_if_curr = "";
    string num_if_next = "";

    while(line_num < total_lines) {
        vector<string> tokens = token_maker(Line_List[line_num]);
        int ts = tokens.size();

        if(is_loop || is_if) {
            string io = tokens[0];
            if(ts==1) {
                if(io[io.length() - 1] == ':') {
                    string trial = io.substr(0,io.length()-1);
                    if(trial == num_loop_next) {
                        is_loop = false;
                        num_loop_curr = "";
                        num_loop_next = "";
                    }
                    if(trial == num_if_next) {
                        is_if = false;
                        num_if_curr = "";
                        num_if_next = "";
                    }
                }
                final_list.push_back(Line_List[line_num]);
            }
            else {
                if(values.find(io) != values.end()) { 
                    values.erase(io);
                }
                final_list.push_back(Line_List[line_num]);
            }
            line_num++;
            continue ;
        }

        if(ts == 5) {
            string res = tokens[0];
            string arg1 = tokens[2];
            string arg2 = tokens[4];
            string op = tokens[3];
            
            bool dig1 = is_digit(arg1);
            bool dig2 = is_digit(arg2);
           
            if(dig1 && dig2) {
                int result = evaluate(to_int(arg1), op, to_int(arg2));
                values[res] = result;
            }
            else if(dig1){
                if(values.find(arg2) != values.end()) {
                    int result = evaluate(to_int(arg1),op,values[arg2]);
                    values[res] = result;
                }
                else {
                    if(values.find(res) != values.end()) {
                        values.erase(res);
                    }
                    final_list.push_back(Line_List[line_num]);
                }
            }
            else if(dig2){
                if(values.find(arg1) != values.end()) {
                    int result = evaluate(values[arg1],op,to_int(arg2));
                    values[res] = result;
                }
                else {
                    if(values.find(res) != values.end()) {
                        values.erase(res);
                    }
                    final_list.push_back(Line_List[line_num]);
                }
            }
            else{
                bool a1 = values.find(arg1) != values.end();
                bool a2 = values.find(arg2) != values.end();
                if(a1 && a2) {
                    int result = evaluate(values[arg1],op,values[arg2]);
                    values[res] = result;
                }
                else if(a1) {
                    string to_pr = res + " = " + to_str(values[arg1]) + " " + op + " " + arg2 + ";";
                    final_list.push_back(to_pr);
                }
                else if(a2) {
                    string to_pr = res + " = " + arg1 + " "+ op + " " + to_str(values[arg2]) + ";";
                    final_list.push_back(to_pr);
                }
                else{
                    if(values.find(res) != values.end()) {
                        values.erase(res);
                    }
                    final_list.push_back(Line_List[line_num]);
                }
            }
        }
        else if(ts == 4){
            // T1 = ! t0
            string res = tokens[0];
            string arg = tokens[3];
            string op = tokens[2];

            if(arg.length()>=2 && arg.substr(0,2) == "IF") { 
                is_if = true;
                num_if_curr = arg;
                num_if_next = "END" + arg;
                final_list.push_back(Line_List[line_num]);
            }
            else if(values.find(arg) != values.end()) {
                int result = evaluate(values[arg],op,1);
                final_list.push_back(Line_List[line_num]);
                values[res] = result;
            }
            else {
                if(values.find(res) != values.end()) {
                        values.erase(res);
                }
                final_list.push_back(Line_List[line_num]);
            }

        }
        else if(ts == 3){
            string res = tokens[0];
            string arg = tokens[2];

            bool dig = is_digit(arg);
            if(dig) {
                values[res] = to_int(arg);
                final_list.push_back(Line_List[line_num]);
            }
            else {
                if(values.find(arg) != values.end()) { 
                    values[res] = values[arg];
                    string to_add = res + " = " + to_str(values[arg]) + ";";
                    final_list.push_back(to_add);
                }
                else {
                    if(values.find(res) != values.end()) {
                        values.erase(res);
                    }
                    final_list.push_back(Line_List[line_num]);
                }
            } 
        }
        else if(ts == 2) {

        }
        else{
            string io = tokens[0];
            if(io[io.length() - 1] == ':') {
                num_loop_curr = io.substr(0,io.length() - 1);
                string p1 = "";
                string p2 = "";
                for(int i=0;i<num_loop_curr.length();i++) {
                    if(num_loop_curr[i]>='0' && num_loop_curr[i]<='9') {
                        p2 += num_loop_curr[i];
                    }
                    else{
                        p1 += num_loop_curr[i];
                    }
                }
                num_loop_next = p1 + to_str(to_int(p2) + 1);
                is_loop = true;
                final_list.push_back(Line_List[line_num]);
            }
            else if(io.substr(0,3) == "cin") {
                string var_name = io.substr(5);
                if(values.find(var_name) != values.end()) {
                    values.erase(var_name);
                }
                final_list.push_back(Line_List[line_num]);
            }
            else {
                string var_name = "";
                int ptr = 6;
                while(ptr<io.length() && io[ptr]!='<') {
                    var_name += io[ptr++];
                }
                if(values.find(var_name) != values.end()) {
                    string to_pr = "cout<<" + to_str(values[var_name]);
                    if(ptr != io.length()) {
                        to_pr += "<<endl;";
                    }
                    else{
                        to_pr += ";";
                    }
                    final_list.push_back(to_pr);
                }
                else{
                    final_list.push_back(Line_List[line_num]);
                }
            }
        }
        line_num++;
    }
}

int main() {
    //Creating an empty list
    vector<string>Line_List;

    //Open ICG file and read line by line
    ifstream reader_icg("ICG.txt");
    string line;
    while(getline(reader_icg, line)) {
        Line_List.push_back(line);
    }

    //Print the ICG file read previously
    // print_icg(Line_List);
    ofstream fout("OptimizedICG.txt");
    cout<<"\n\n********************Optimizer Running********************\n\n";
    folding(Line_List);

    for(int i=0;i<final_list.size();i++) {
        fout<<final_list[i]<<endl;
    }

    cout<<"\n\n********************Optimization Successfull********************\n\n";
    fout.close();
    reader_icg.close();

    return 0;
}

// g++ -std=c++11 -g -o a ramu_optimizer.cpp