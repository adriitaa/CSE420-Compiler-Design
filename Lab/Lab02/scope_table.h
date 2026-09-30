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
        // write your hash function here
        int hash_value = 0;
        for (char ch : name)
        {
            hash_value += (int)ch;
        }
        int idx = hash_value % bucket_count;
        return idx;
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

    // you can add more methods if you need   
};

scope_table::scope_table()
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
    table.resize(bucket_count);
}

scope_table* scope_table::get_parent_scope()
{
    return parent_scope;
}

int scope_table::get_unique_id()
{
    return unique_id;
}

symbol_info* scope_table::lookup_in_scope(symbol_info* symbol)
{
    int index = hash_function(symbol->get_name());

    for(symbol_info* s : table[index])
    {
        if(s->get_name() == symbol->get_name())
            return s;
    }
    return NULL;
}

bool scope_table::insert_in_scope(symbol_info* symbol)
{
    if(lookup_in_scope(symbol) != NULL)
        return false;
    int index = hash_function(symbol->get_name());
    table[index].push_back(symbol);
    return true;
}
 

bool scope_table::delete_from_scope(symbol_info* symbol)
{
    int index = hash_function(symbol->get_name());
    auto &bucket = table[index];
    for(auto it = bucket.begin(); it != bucket.end(); ++it)
    {
        if((*it)->get_name() == symbol->get_name())
        {
            delete *it;
            bucket.erase(it);
            return true;
        }
    }

    return false;
}

// complete the methods of scope_table class
void scope_table::print_scope_table(ofstream& outlog)
{
    outlog << "ScopeTable # "+ to_string(unique_id) << endl;

    //iterate through the current scope table and print the symbols and all relevant information
    for(int i = 0; i < bucket_count; i++)
    {
        if(table[i].empty())
            continue;
        outlog << i << " -->" << endl;

        for(symbol_info* s : table[i])
        {
            outlog << "< "
                   << s->get_name()
                   << " : "
                   << s-> get_type()
                   << " >"
                   << endl;
            
            outlog << s->get_symbol_type() << endl;

            if(s->get_symbol_type() == "Variable" || s->get_symbol_type() == "Array")
            {
                outlog << "Type: " 
                       << s->get_data_type() 
                       << endl;
            }

            if(s->get_symbol_type() == "Array")
            {
                outlog << "Size: "
                       << s->get_array_size()
                       << endl;
            }

            if(s->get_symbol_type() == "Function Definition")
            {
                outlog << "Return Type: " 
                       << s->get_return_type() 
                       << endl;
                outlog << "Number of Parameters: "
                       << s->get_parameter_count()
                       << endl;

                outlog << "Parameter Details: ";

                auto types = s->get_parameter_types();
                auto names = s->get_parameter_names();

                for(int j = 0; j < types.size(); j++)
                {
                    outlog << types[j];
                    if(names[j] != "")
                        outlog << " " << names[j];
                    
                    if(j!= types.size() - 1)
                        outlog << ", ";
                }

                outlog << endl;
            }

            outlog << endl;
        }
    }
}

scope_table::~scope_table()
{
    for(auto &bucket : table)
    {
        for(symbol_info *symbol : bucket)
        {
            delete symbol;
        }
    }
}
