#include "symbol_info.h"

class scope_table
{
private:
    int bucket_count;
    int unique_id;
    scope_table *parent_scope = NULL;
    vector<list<symbol_info *>> table;

    int hash_function(string name)
    {
        int sum = 0;
        for (char c : name)
            sum += c;
        return sum % bucket_count;
    }

public:
    scope_table();
    scope_table(int bucket_count, int unique_id, scope_table *parent_scope);
    scope_table *get_parent_scope();
    int get_unique_id();
    symbol_info *lookup_in_scope(symbol_info* symbol);
    bool insert_in_scope(symbol_info* symbol);
    bool delete_from_scope(symbol_info* symbol);
    void print_scope_table(ofstream& outlog);
    ~scope_table();
};

scope_table::scope_table() //initial
{
    bucket_count = 0;
    unique_id = 0;
    parent_scope = NULL;
}

scope_table::scope_table(int bucket_count, int unique_id, scope_table *parent_scope)
{
    this->bucket_count = bucket_count;
    this->unique_id = unique_id;
    this->parent_scope = parent_scope;
    this->table = vector<list<symbol_info *>>(bucket_count);
}

scope_table *scope_table::get_parent_scope()
{
    return parent_scope;
}

int scope_table::get_unique_id()
{
    return unique_id;
}

symbol_info *scope_table::lookup_in_scope(symbol_info* symbol)
{
    int index = hash_function(symbol->get_name());
    for (symbol_info* s : table[index])
    {
        if (s->get_name() == symbol->get_name())
            return s;
    }
    return NULL;
}

bool scope_table::insert_in_scope(symbol_info* symbol)
{
    if (lookup_in_scope(symbol) != NULL)
        return false;

    int index = hash_function(symbol->get_name());
    table[index].push_back(symbol);
    return true;
}

bool scope_table::delete_from_scope(symbol_info* symbol)
{
    int index = hash_function(symbol->get_name());
    for (auto it = table[index].begin(); it != table[index].end(); ++it)
    {
        if ((*it)->get_name() == symbol->get_name())
        {
            delete *it;
            table[index].erase(it); //list theke node remove
            return true;
        }
    }
    return false;
}

void scope_table::print_scope_table(ofstream& outlog)
{
    outlog << "ScopeTable # " << unique_id << endl;

    for (int i = 0; i < bucket_count; i++)
    {
        if (table[i].empty())
            continue;

        outlog << i << " --> " << endl;

        for (symbol_info* s : table[i])
        {
            outlog << "< " << s->get_name() << " : " << s->get_type() << " >" << endl;

            string symbol_type = s->get_symbol_type();
            if (symbol_type == "function")
            {
                outlog << "Function Definition" << endl;
                outlog << "Return Type: " << s->get_data_type() << endl;
                outlog << "Number of Parameters: " << s->get_param_count() << endl;
                outlog << "Parameter Details: " << s->get_param_details() << endl;
            }
            else if (symbol_type == "array")
            {
                outlog << "Array" << endl;
                outlog << "Type: " << s->get_data_type() << endl;
                outlog << "Size: " << s->get_array_size() << endl;
                outlog << endl;
            }
            else 
            {
                outlog << "Variable" << endl;
                outlog << "Type: " << s->get_data_type() << endl;
                outlog << endl;
            }
        }
    }
}

scope_table::~scope_table()
{
    for (int i = 0; i < bucket_count; i++)
    {
        for (symbol_info* s : table[i])
            delete s;
    }
}
