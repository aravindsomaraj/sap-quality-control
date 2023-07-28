import streamlit as st
import pandas as pd
import psycopg2

# Database connection parameters (replace with your database credentials)
db_params = {
    'host': '127.0.0.1',
    'database': 'batchvs',
    'user': 'buu',
    'password': 'chessiscool'
}

def fetch_unreleased_inspection_data():
    connection = psycopg2.connect(**db_params)
    query = """
            SELECT * FROM get_unreleased_lots();
    """
    data = pd.read_sql_query(query, connection)
    connection.close()
    return data

def fetch_all_batches_data():
    connection = psycopg2.connect(**db_params)
    query = """
            SELECT * FROM get_all_batches();
    """
    data = pd.read_sql_query(query, connection)
    connection.close()
    return data

def fetch_sample_details(sample_id):
    connection = psycopg2.connect(**db_params)
    query = """
            SELECT * FROM get_sample_details(%s);
    """
    data = pd.read_sql_query(query, connection, params=(sample_id,))
    connection.close()
    return data

def fetch_analysts_info(sample_id):
    connection = psycopg2.connect(**db_params)
    query = """
            SELECT a.analyst_id,a.name,a.email
            FROM get_sample_details(%s) s
            JOIN analyst a ON s.analyst_name = a.name;
    """
    data = pd.read_sql_query(query, connection, params=(sample_id,))
    connection.close()
    return data

def main():
    st.title('Unreleased Lot Inspections')

    # Fetch unreleased inspection data from the database
    unreleased_data = fetch_unreleased_inspection_data()
    all_batch_data  = fetch_all_batches_data()
    # Add a text input box for inspection ID
    inspection_id = st.text_input('Enter Inspection Lot ID:', '')

    # Filter data based on the input ID
    if inspection_id:
        sample_data = fetch_sample_details(inspection_id)
        if not sample_data.empty:
            st.table(sample_data)

            # Button to show list of analysts info
            if st.button('Show Analysts Involved'):
                analysts_data = fetch_analysts_info(inspection_id)
                if not analysts_data.empty:
                    st.write('List of Analysts Involved:')
                    st.write(analysts_data)
                else:
                    st.warning('No analysts found for the entered Inspection Lot ID.')
        else:
            st.warning('No data found for the entered Inspection Lot ID.')

    # Create two columns for the buttons
    col1, col2 = st.columns([2,3])

    # Button to show unreleased inspection lots
    if col1.button('Show Unreleased Inspection Lots'):
        st.table(unreleased_data)

    # Button to display the table of batches and their status
    if col2.button('Show all Batches'):
        st.table(all_batch_data)

if __name__ == '__main__':
    main()
