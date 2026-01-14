import 'dart:async';

import 'package:dakara_weighbridge/Json/listtransaction_json.dart';
import 'package:dakara_weighbridge/SQLite/db_helper.dart';
import 'package:flutter/material.dart';

class SearchTicketField extends StatefulWidget {
  final void Function(ListTransactionJson transactions) onSelected;

  const SearchTicketField({super.key, required this.onSelected});

  @override
  State<SearchTicketField> createState() => _SearchTicketFieldState();
}

class _SearchTicketFieldState extends State<SearchTicketField> {
  Timer? _debounce;
  List<ListTransactionJson> _results = [];

  void _onChanged(String query) {
    _debounce?.cancel();

    _debounce = Timer(const Duration(milliseconds: 400), () async {
      if (query.isEmpty) {
        setState(() => _results.clear());
        return;
      }

      final data = await DbHelper.instance.getTransactionByNoTicket(
        noTicket: query,
      );
      if (!mounted) return;

      setState(() => _results = data);
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TextField(
          onChanged: _onChanged,
          decoration: const InputDecoration(
            labelStyle: TextStyle(color: Colors.white),
            labelText: 'No Tiket',
            prefixIcon: Icon(Icons.search),
          ),
        ),

        ListView.builder(
          shrinkWrap: true,
          itemCount: _results.length,
          itemBuilder: (context, index) {
            final transaction = _results[index];
            return ListTile(
              tileColor: Colors.black,
              title: Text(
                '${transaction.driverName} - ${transaction.noTicket}',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              subtitle: Text(
                'Gross: ${transaction.bruto}',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w100,
                ),
              ),
              onTap: () {
                widget.onSelected(transaction);
                setState(() => _results.clear());
              },
            );
          },
        ),
      ],
    );
  }
}
