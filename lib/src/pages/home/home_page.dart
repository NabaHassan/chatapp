import 'package:chatapp/src/pages/group/group_chat.dart';
import 'package:flutter/material.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final TextEditingController _nameController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Chat App')),
      body: Center(
        child: TextButton(
          onPressed: () {
            showDialog(
              context: context,
              builder: (BuildContext dialogContext) {
                return AlertDialog(
                  title: const Text("Enter your name:"),
                  content: Form(
                    key: _formKey,
                    child: TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(hintText: "Name"),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Naam nahi dala?';
                        }
                        return null;
                      },
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () {
                        if (_formKey.currentState!.validate()) {
                          // pop the dialog first
                          Navigator.of(dialogContext).pop();
                          // show snack & navigate using the outer context (the page's context)
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              duration: const Duration(seconds: 1),
                              content: Text(
                                'Welcome ${_nameController.text.trim()}',
                              ),
                            ),
                          );
                          // navigate to ChatPage
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) =>
                                  GroupPage(name: _nameController.text.trim()),
                            ),
                          );
                          
                        }
                      },
                      child: const Text('Enter'),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.of(dialogContext).pop();
                      },
                      child: const Text('Cancel'),
                    ),
                  ],
                );
              },
            );
          },
          child: const Text('Go to Chat'),
        ),
      ),
    );
  }
}
