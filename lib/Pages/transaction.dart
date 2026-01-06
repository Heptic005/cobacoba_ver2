import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
// import 'package:dakara_weighbridge/SQLite/db_helper.dart'; // Commented out for now if not used directly for dropdowns yet, but needed for recent transactions?
import 'package:dakara_weighbridge/SQLite/db_helper.dart';
import 'package:dakara_weighbridge/Json/listtransaction_json.dart';

class Transaction extends StatefulWidget {
  const Transaction({super.key});

  @override
  State<Transaction> createState() => _TransactionState();
}

class _TransactionState extends State<Transaction> {
  late String _timeString;
  late Timer _timer;
  Color limeGreen = const Color(0xFF97FF21);
  bool _isWeighIn = true;
  String _displayWeight = '0';

  // Colors based on design
  final Color _bgDark = const Color(0xFF1E2126);
  final Color _cardBg = const Color(0xFF2B2E33);
  final Color _primaryCyan = const Color(0xFF00E5FF);
  final Color _textWhite = Colors.white;
  final Color _textGrey = const Color(0xFFBFC9D6);
  final Color _inputBg = const Color(0xFF383C42);

  final platnomorController = TextEditingController();
  final poController = TextEditingController();
  final namasupirController = TextEditingController();

  final focusPlatnomor = FocusNode();
  final focusPO = FocusNode();
  final focusSupir = FocusNode();

  // Mock Data Lists
  final List<String> _suppliers = [
    'PT. Supplier A',
    'PT. Supplier B',
    'CV. Maju Jaya',
  ];
  final List<String> _customers = [
    'PT. Customer X',
    'PT. Customer Y',
    'Toko Bangunan Z',
  ];
  final List<String> _products = ['Batu Split', 'Pasir', 'Sirtu', 'Tanah Urug'];

  // Selected Values for Dropdowns
  String? _selectedSupplier;
  String? _selectedCustomer;
  String? _selectedProduct;

  @override
  void initState() {
    super.initState();
    _timeString = _formatDateTime(DateTime.now());
    _timer = Timer.periodic(
      const Duration(seconds: 1),
      (Timer t) => _getTime(),
    );
  }

  @override
  void dispose() {
    _timer.cancel();
    platnomorController.dispose();
    poController.dispose();
    namasupirController.dispose();
    focusPlatnomor.dispose();
    focusPO.dispose();
    focusSupir.dispose();
    super.dispose();
  }

  void _getTime() {
    final DateTime now = DateTime.now();
    setState(() {
      _timeString = _formatDateTime(now);
    });
  }

  String _formatDateTime(DateTime dateTime) {
    return DateFormat('HH:mm:ss').format(dateTime);
  }

  void _setWeightFromIndicator() {
    setState(() {
      _displayWeight = '0';
    });
  }

  String _formatShortDate(String? raw) {
    if (raw == null) return '';
    try {
      final dt = DateTime.tryParse(raw);
      if (dt != null) return DateFormat('dd MMM HH:mm').format(dt);
      return raw;
    } catch (e) {
      return raw;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgDark,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            const SizedBox(height: 10),
            // HEADER
            _buildHeader(),
            const SizedBox(height: 20),

            // TOP SECTION: Weight Monitor + Buttons
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(flex: 3, child: _buildWeightMonitorCard()),
                const SizedBox(width: 20),
                Expanded(flex: 2, child: _buildMainActions()),
              ],
            ),
            const SizedBox(height: 20),

            // BOTTOM SECTION: Form + Details
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(flex: 3, child: _buildFormCard(context)),
                const SizedBox(width: 20),
                Expanded(flex: 2, child: _buildWeightDetails()),
              ],
            ),
            const SizedBox(height: 30),
            // RECENT TRANSACTIONS
            _buildRecentTransactions(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return SizedBox(
      width: double.infinity,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 8.0),
            child: Text(
              "PT. Dakara Prima Internasional",
              style: TextStyle(
                fontSize: 24,
                color: Colors.white,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox.shrink(),
        ],
      ),
    );
  }

  Widget _buildWeightMonitorCard() {
    return Container(
      height: 280,
      padding: const EdgeInsets.all(30),
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: limeGreen,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(color: limeGreen.withValues(alpha: 0.6), blurRadius: 6),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Text(
                "Weighing Indicator",
                style: TextStyle(
                  color: _textGrey.withValues(alpha: 0.85),
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  shadows: [
                    const Shadow(
                      color: Colors.black26,
                      offset: Offset(0, 1),
                      blurRadius: 1,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const Spacer(),
          Text(
            "$_displayWeight kg",
            style: TextStyle(
              fontSize: 90,
              color: _textWhite,
              fontWeight: FontWeight.bold,
              height: 1.0,
              shadows: [
                Shadow(
                  color: Colors.black54,
                  offset: Offset(0, 2),
                  blurRadius: 6,
                ),
              ],
            ),
          ),
          const Spacer(),
          ElevatedButton(
            onPressed: _setWeightFromIndicator,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: Colors.black,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
              shape: const StadiumBorder(),
            ),
            child: Text(
              'Capture Weight',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMainActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        ElevatedButton.icon(
          onPressed: () => setState(() => _isWeighIn = true),
          icon:
              _isWeighIn
                  ? const Icon(Icons.check, size: 20)
                  : const SizedBox.shrink(),
          label: const Text("Timbang Masuk"),
          style: ElevatedButton.styleFrom(
            backgroundColor: _isWeighIn ? _primaryCyan : Colors.transparent,
            foregroundColor: _isWeighIn ? Colors.black : Colors.white,
            elevation: 0,
            side:
                _isWeighIn
                    ? BorderSide.none
                    : BorderSide(color: _textGrey.withValues(alpha: 0.6)),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            textStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        const SizedBox(height: 12),
        ElevatedButton.icon(
          onPressed: () => setState(() => _isWeighIn = false),
          icon:
              !_isWeighIn
                  ? const Icon(Icons.check, size: 20)
                  : const SizedBox.shrink(),
          label: const Text("Timbang Keluar"),
          style: ElevatedButton.styleFrom(
            backgroundColor: !_isWeighIn ? Colors.white : Colors.transparent,
            foregroundColor: !_isWeighIn ? Colors.black : Colors.white,
            elevation: 0,
            side:
                !_isWeighIn
                    ? BorderSide.none
                    : BorderSide(color: _textGrey.withValues(alpha: 0.6)),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            textStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: const Color(0xFF23262B),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _textGrey.withValues(alpha: 0.12)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                _timeString,
                style: TextStyle(
                  color: _textWhite,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                DateFormat("EEEE, d MMMM yyyy", "id_ID").format(DateTime.now()),
                style: TextStyle(color: _textGrey),
              ),
              const SizedBox(height: 8),
              Divider(color: _textGrey.withValues(alpha: 0.12)),
              const SizedBox(height: 8),
              Text('Indicator : GST-9000', style: TextStyle(color: _textGrey)),
              Text('Connected to PORT1', style: TextStyle(color: _textGrey)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFormCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 8),
        ],
      ),
      child: Column(
        children: [
          _buildTextInput(
            controller: platnomorController,
            label: "Plat Nomor",
            hint: "B 1234 ABC",
            focus: focusPlatnomor,
            nextFocus: focusSupir,
            textCapital: TextCapitalization.characters,
            prefixIcon: Icons.local_shipping_outlined,
            context: context,
          ),
          const SizedBox(height: 16),
          _buildTextInput(
            controller: namasupirController,
            label: "Nama Supir",
            focus: focusSupir,
            prefixIcon: Icons.person_outline,
            context: context,
          ),
          const SizedBox(height: 16),

          // SUPPLIER DROPDOWN
          _buildDropdown(
            label: "Supplier",
            value: _selectedSupplier,
            items: _suppliers,
            prefixIcon: Icons.store_mall_directory_outlined,
            onChanged: (val) => setState(() => _selectedSupplier = val),
          ),
          const SizedBox(height: 16),

          // CUSTOMER DROPDOWN
          _buildDropdown(
            label: "Customer",
            value: _selectedCustomer,
            items: _customers,
            prefixIcon: Icons.business_outlined,
            onChanged: (val) => setState(() => _selectedCustomer = val),
          ),
          const SizedBox(height: 16),

          // BARANG DROPDOWN
          _buildDropdown(
            label: "Barang",
            value: _selectedProduct,
            items: _products,
            prefixIcon: Icons.category_outlined,
            onChanged: (val) => setState(() => _selectedProduct = val),
          ),

          const SizedBox(height: 16),
          _buildTextInput(
            controller: poController,
            label: "Nomor DO / PO",
            focus: focusPO,
            prefixIcon: Icons.description_outlined,
            context: context,
          ),

          const SizedBox(height: 32),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                // Save logic placeholder
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: _primaryCyan,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 22),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(50),
                ),
                textStyle: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                ),
              ),
              child: Text(_isWeighIn ? "SIMPAN MASUK" : "SIMPAN KELUAR"),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeightDetails() {
    return Column(
      children: [
        _buildDetailCard("Bruto", "0 kg"),
        const SizedBox(height: 16),
        _buildDetailCard("Tara", "0 kg"),
        const SizedBox(height: 16),
        _buildDetailCard("Netto", "0 kg"),
      ],
    );
  }

  Widget _buildDetailCard(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
      decoration: BoxDecoration(
        color: const Color(0xFF23262B),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _textGrey.withValues(alpha: 0.12)),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 4),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(color: _textGrey, fontSize: 14)),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextInput({
    required TextEditingController controller,
    required BuildContext context,
    required String label,
    String? hint,
    FocusNode? focus,
    FocusNode? nextFocus,
    TextCapitalization textCapital = TextCapitalization.none,
    Icon? suffixIcon,
    IconData? prefixIcon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: controller,
          focusNode: focus,
          textCapitalization: textCapital,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w500,
          ),
          decoration: InputDecoration(
            labelText: label,
            labelStyle: TextStyle(color: _textGrey),
            hintText: hint,
            hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.5)),
            filled: true,
            fillColor: _inputBg,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 18,
            ),
            prefixIcon:
                prefixIcon != null ? Icon(prefixIcon, color: _textGrey) : null,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: _textGrey.withValues(alpha: 0.12)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: _primaryCyan, width: 1.5),
            ),
            suffixIcon: suffixIcon,
          ),
          onFieldSubmitted: (v) {
            if (nextFocus != null) {
              FocusScope.of(context).requestFocus(nextFocus);
            }
          },
        ),
      ],
    );
  }

  Widget _buildDropdown({
    required String label,
    required List<String> items,
    required Function(String?) onChanged,
    String? value,
    String? hint,
    IconData? prefixIcon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DropdownButtonFormField<String>(
          initialValue: value,
          items:
              items.map((String item) {
                return DropdownMenuItem<String>(
                  value: item,
                  child: Text(
                    item,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                );
              }).toList(),
          onChanged: onChanged,
          dropdownColor: _inputBg, // Ensure dropdown popup matches input bg
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w500,
          ), // Selected text color
          decoration: InputDecoration(
            labelText: label,
            labelStyle: TextStyle(color: _textGrey),
            hintText: hint,
            hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.4)),
            filled: true,
            fillColor: _inputBg,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 18,
            ),
            prefixIcon:
                prefixIcon != null ? Icon(prefixIcon, color: _textGrey) : null,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: _textGrey.withValues(alpha: 0.12)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: _primaryCyan, width: 1.5),
            ),
          ),
          icon: Icon(Icons.arrow_drop_down, color: _textGrey),
        ),
      ],
    );
  }

  Widget _buildRecentTransactions() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _textGrey.withValues(alpha: 0.12), width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Recent Transactions',
            style: TextStyle(fontSize: 16, color: Colors.white),
          ),
          const SizedBox(height: 16),
          FutureBuilder<List<ListTransactionJson>>(
            future: DbHelper.instance.getListTransaction(),
            builder: (context, snapshot) {
              if (snapshot.connectionState != ConnectionState.done) {
                return const SizedBox(
                  height: 50,
                  child: Center(child: CircularProgressIndicator()),
                );
              }
              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Center(
                    child: Text(
                      'No recent transactions',
                      style: TextStyle(color: _textGrey.withValues(alpha: 0.9)),
                    ),
                  ),
                );
              }

              final items = snapshot.data!;
              return ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: items.length,
                separatorBuilder:
                    (_, __) => Divider(color: _textGrey.withValues(alpha: 0.12)),
                itemBuilder: (ctx, i) {
                  final it = items[i];
                  final plate = it.vehiclePlate?.toString() ?? '-';
                  final bruto = it.bruto?.toString() ?? '0';
                  final netto = it.netto?.toString() ?? '0';
                  final intimeRaw = it.inTime?.toString();
                  final intime = _formatShortDate(intimeRaw);

                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              plate,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              intime,
                              style: TextStyle(color: _textGrey, fontSize: 12),
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  '$bruto kg',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Bruto',
                                  style: TextStyle(
                                    color: _textGrey.withValues(alpha: 0.7),
                                    fontSize: 10,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(width: 15),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  '$netto kg',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Netto',
                                  style: TextStyle(
                                    color: _textGrey.withValues(alpha: 0.7),
                                    fontSize: 10,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }
}
