#include "scope_table.h"
#include <iostream>
#include <fstream>

class symbol_table
{
private:
    scope_table *current_scope;
    int bucket_count;
    int current_scope_id;

public:
    symbol_table(int bucket_count)
    {
        this->bucket_count = bucket_count;
        this->current_scope = NULL;
        this->current_scope_id = 1;
    }
    ~symbol_table()
    {
        while (current_scope != NULL)
        {
            scope_table *temp = current_scope;
            current_scope = current_scope->get_parent_scope();
            delete temp;
        }
    }
    void enter_scope(ofstream &outlog)
    {
        scope_table *new_scope = new scope_table(bucket_count, current_scope_id++, current_scope);
        current_scope = new_scope;

        outlog << "New ScopeTable with ID " << current_scope->get_unique_id() << " created\n" << endl;

    }
    void exit_scope(ofstream &outlog)
    {
        if (current_scope == NULL)
        {
            return;
        }
        outlog << "Scopetable with ID " << current_scope->get_unique_id() << " removed\n" << endl;
        scope_table *parent_scope = current_scope->get_parent_scope();
        delete current_scope;
        current_scope = parent_scope;
    }
    bool insert(symbol_info* symbol)
    {
        if (current_scope == NULL)
        {
            return false;
        }
        return current_scope->insert_in_scope(symbol);
    }

    bool remove(symbol_info* symbol)
    {
        if(current_scope == NULL) return false;
        return current_scope->delete_from_scope(symbol);
    }
    symbol_info* lookup(symbol_info* symbol)
    {
        scope_table *temp = current_scope;
        while (temp != NULL)
        {
            symbol_info *found_sym = temp->lookup_in_scope(symbol);
            if (found_sym != NULL)
            {
                return found_sym;
            }
            temp = temp->get_parent_scope();
        }
        return NULL;
    }
    void print_current_scope(ofstream &outlog)
    {
        if (current_scope == NULL)
        {
            return;
        }
        outlog << "################################" <<endl<<endl;
        current_scope->print_scope_table(outlog);
        outlog << "################################" <<endl<<endl;
    }
    void print_all_scopes(ofstream& outlog)
    {
        outlog << "################################" <<endl<<endl;
        scope_table *temp = current_scope;
        while (temp != NULL)
        {
            temp->print_scope_table(outlog);
            temp = temp->get_parent_scope();
        }
        outlog << "################################" <<endl<<endl;
    }

    // you can add more methods if you need 
};

// complete the methods of symbol_table class


// void symbol_table::print_all_scopes(ofstream& outlog)
// {
//     outlog<<"################################"<<endl<<endl;
//     scope_table *temp = current_scope;
//     while (temp != NULL)
//     {
//         temp->print_scope_table(outlog);
//         temp = temp->get_parent_scope();
//     }
//     outlog<<"################################"<<endl<<endl;
// }