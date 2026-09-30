#include<bits/stdc++.h>
using namespace std;

class symbol_info
{
private:
    string name;
    string type;

    // Write necessary attributes to store what type of symbol it is (variable/array/function)
    string symbol_type;
    // Write necessary attributes to store the type/return type of the symbol (int/float/void/...)
    string data_type;
    string return_type;
    // Write necessary attributes to store the parameters of a function
    vector<string> parameter_types;
    vector<string>parameter_names;
    // Write necessary attributes to store the array size if the symbol is an array
    int array_size;
    
public:
    symbol_info(string name, string type)
    {
        this->name = name;
        this->type = type;
        this->symbol_type="";
        this->data_type="";
        this->return_type="";
        this->array_size= 0;
    }
    string get_name()
    {
        return name;
    }
    string get_type()
    {
        return type;
    }
    void set_name(string name)
    {
        this->name = name;
    }
    void set_type(string type)
    {
        this->type = type;
    }
    // Write necessary functions to set and get the attributes

    string getname()
    {
        return get_name();
    }

    string get_symbol_type()
    {
        return symbol_type;
    }
    
    void set_symbol_type(string symbol_type)
    {
        this->symbol_type = symbol_type;
    }
    

    
    string get_data_type()
    {
        return data_type;
    }
    
    void set_data_type(string data_type)
    {
        this->data_type = data_type;
    }

    string get_return_type()
    {
        return return_type;
    }

    void set_return_type(string return_type)
    {
        this->return_type = return_type;
    }
    
    void set_array_size(int size)
    {
        this->array_size = size;
    }
    int get_array_size()
    {
        return array_size;
    }

    
    void add_parameter(string datatype, string name)
    {
        parameter_types.push_back(datatype);
        parameter_names.push_back(name);
    }

    vector<string> get_parameter_types()
    {
        return parameter_types;
    }

    vector<string> get_parameter_names()
    {
        return parameter_names;
    }

    int get_parameter_count()
    {
        return parameter_types.size();
    }
    ~symbol_info()
    {
        // Write necessary code to deallocate memory, if necessary
        parameter_types.clear();
        parameter_names.clear();
    }
};