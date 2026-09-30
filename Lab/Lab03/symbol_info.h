#include<bits/stdc++.h>
using namespace std;

class symbol_info
{
private:
    string name;
    string type;

    string symbol_type;
    string data_type;
    string array_size;
    vector<pair<string, string>> parameters;

public:
    symbol_info(string name, string type)
    {
        this->name = name;
        this->type = type;
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

    void set_symbol_type(string symbol_type)
    {
        this->symbol_type = symbol_type;
    }
    string get_symbol_type()
    {
        return symbol_type;
    }

    void set_data_type(string data_type)
    {
        this->data_type = data_type;
    }
    string get_data_type()
    {
        return data_type;
    }

    void set_array_size(string array_size)
    {
        this->array_size = array_size;
    }
    string get_array_size()
    {
        return array_size;
    }

    void add_param(string param_type, string param_name)
    {
        parameters.push_back(make_pair(param_type, param_name));
    }
    int get_param_count()
    {
        return parameters.size();
    }
    vector<pair<string, string>> get_params()
    {
        return parameters;
    }

    void set_params(vector<pair<string, string>> params)
    {
        this->parameters = params;
    }
    string get_param_details()
    {
        string details = "";
        for (int i = 0; i < (int)parameters.size(); i++)
        {
            if (i > 0)
                details += ", ";
            details += parameters[i].first + " " + parameters[i].second;
        }
        return details;
    }

    ~symbol_info()
    {
        
    }
};
