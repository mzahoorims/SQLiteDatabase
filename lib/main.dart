import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';


void main() => runApp(MyApp()); // The main function, which is the entry point of the app.

class MyApp extends StatelessWidget { // Defining a stateless widget for the app.
  @override
  Widget build(BuildContext context) {
    return MaterialApp( // Creating the MaterialApp, the root of the app.
      title: 'SQLite Demo', // Setting the title of the app.
      home: HomeScreen(), // Setting HomeScreen as the home page of the app.
    );
  }
}

class HomeScreen extends StatefulWidget { // Defining a stateful widget for the home screen.
  @override
  _HomeScreenState createState() => _HomeScreenState(); // Creating the state for the home screen.
}

class _HomeScreenState extends State<HomeScreen> {
  Database? database; // Database variable to hold the SQLite database instance.
  List<Map<String, dynamic>> data = []; // List to store the fetched data from the database.
  TextEditingController textController = TextEditingController(); // Controller for the text input field.
  TextEditingController updateController = TextEditingController(); // Controller for the update text input field.
  TextEditingController searchController = TextEditingController(); // Controller for the search text input field.

  @override
  void initState() {
    super.initState();
    _initializeDatabase(); // Initialize the database when the widget is created.
  }

  Future<void> _initializeDatabase() async {
    database = await openDatabase( // Opening the database and storing the instance in the 'database' variable.
      join(await getDatabasesPath(), 'demo.db'), // Setting the path for the database file.
      onCreate: (db, version) { // Function to create the database if it doesn't exist.
        return db.execute(
          "CREATE TABLE items(id INTEGER PRIMARY KEY AUTOINCREMENT, text TEXT)", // SQL query to create a table named 'items'.
        );
      },
      version: 1, // Setting the version of the database.
    );
    _fetchData(); // Fetch the data after initializing the database.
  }

  Future<void> _saveData() async {
    if (textController.text.isNotEmpty) { // Check if the input field is not empty.
      await database?.insert(
        'items', // Inserting data into the 'items' table.
        {'text': textController.text}, // Inserting the text from the input field.
        conflictAlgorithm: ConflictAlgorithm.replace, // Replacing the data if there is a conflict.
      );
      textController.clear(); // Clear the input field after saving the data.
      _fetchData(); // Fetch the updated data from the database.
    }
  }

  Future<void> _updateData(int id) async {
    if (updateController.text.isNotEmpty) { // Check if the update input field is not empty.
      await database?.update(
        'items', // Updating the 'items' table.
        {'text': updateController.text}, // Updating the text with the new value.
        where: 'id = ?', // SQL condition to specify which row to update.
        whereArgs: [id], // Passing the id of the row to be updated.
      );
      updateController.clear(); // Clear the update input field after updating the data.
      _fetchData(); // Fetch the updated data from the database.
    }
  }

  Future<void> _deleteData(int id) async {
    await database?.delete(
      'items', // Deleting data from the 'items' table.
      where: 'id = ?', // SQL condition to specify which row to delete.
      whereArgs: [id], // Passing the id of the row to be deleted.
    );
    _fetchData(); // Fetch the updated data after deletion.
  }

  Future<void> _fetchData() async {
    final List<Map<String, dynamic>>? items = await database?.query('items'); // Querying the database to fetch all data from the 'items' table.
    setState(() {
      data = items ?? []; // Setting the fetched data to the 'data' list and updating the UI.
    });
  }

  Future<void> _searchData() async {
    final List<Map<String, dynamic>>? results = await database?.query(
      'items', // Querying the database to search for data in the 'items' table.
      where: "text LIKE ?", // SQL condition to search for text matching the input.
      whereArgs: ['%${searchController.text}%'], // Passing the search query with wildcards.
    );
    setState(() {
      data = results ?? []; // Setting the search results to the 'data' list and updating the UI.
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('SQLite Demo'), // Setting the title of the app bar.
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0), // Adding padding to the body of the screen.
        child: Column(
          children: [
            TextField(
              controller: textController, // Assigning the text controller to the input field.
              decoration: InputDecoration(labelText: 'Enter Text'), // Setting the label text for the input field.
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween, // Aligning the buttons horizontally with space between them.
              children: [
                ElevatedButton(
                  onPressed: _saveData, // Save the data when this button is pressed.
                  child: Text('Save'), // Setting the label of the button.
                ),
                ElevatedButton(
                  onPressed: _fetchData, // Fetch all data when this button is pressed.
                  child: Text('Show All'), // Setting the label of the button.
                ),
              ],
            ),
            TextField(
              controller: searchController, // Assigning the search controller to the input field.
              decoration: InputDecoration(labelText: 'Search Text'), // Setting the label text for the search input field.
            ),
            ElevatedButton(
              onPressed: _searchData, // Search the data when this button is pressed.
              child: Text('Search'), // Setting the label of the button.
            ),
            Expanded(
              child: ListView.builder(
                itemCount: data.length, // Setting the number of items in the list view.
                itemBuilder: (context, index) {
                  final item = data[index]; // Getting the item data at the current index.
                  return ListTile(
                    title: Text(item['text']), // Displaying the text of the item.
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min, // Making the row only as wide as necessary.
                      children: [
                        IconButton(
                          icon: Icon(Icons.edit), // Setting the icon for the edit button.
                          onPressed: () {
                            showDialog(
                              context: context,
                              builder: (context) {
                                return AlertDialog(
                                  title: Text('Update Text'), // Setting the title of the update dialog.
                                  content: TextField(
                                    controller: updateController, // Assigning the update controller to the input field.
                                    decoration: InputDecoration(
                                      hintText: 'Enter new text', // Setting the hint text for the update input field.
                                    ),
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () {
                                        Navigator.of(context).pop(); // Close the dialog without making changes.
                                      },
                                      child: Text('Cancel'), // Setting the label of the cancel button.
                                    ),
                                    TextButton(
                                      onPressed: () {
                                        _updateData(item['id']); // Update the data when the update button is pressed.
                                        Navigator.of(context).pop(); // Close the dialog after updating.
                                      },
                                      child: Text('Update'), // Setting the label of the update button.
                                    ),
                                  ],
                                );
                              },
                            );
                          },
                        ),
                        IconButton(
                          icon: Icon(Icons.delete), // Setting the icon for the delete button.
                          onPressed: () => _deleteData(item['id']), // Delete the data when the delete button is pressed.
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
