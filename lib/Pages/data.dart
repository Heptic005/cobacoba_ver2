import 'package:dakara_weighbridge/Json/listproduct_json.dart';
import 'package:dakara_weighbridge/SQLite/db_helper.dart';
import 'package:flutter/material.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class DataCustomerBarang extends StatefulWidget {
  const DataCustomerBarang({super.key});

  @override
  State<DataCustomerBarang> createState() => _DataCustomerBarangState();
}

class _DataCustomerBarangState extends State<DataCustomerBarang> {
  // final db = DbHelper();
  late Future<List<ListProductJson>> listProduct;

  final searchController = TextEditingController();

  @override
  void initState() {
    // dbHandler.init().whenComplete(() => listProduct = getAllListProduct());

    super.initState();
    listProduct = DbHelper.instance.getListProducts();
  }

  // Future<List<ListProductJson>> getAllListProduct() async {
  //   return await dbHandler.getListProducts();
  // }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(vertical: 90, horizontal: 50),
      child: Row(
        children: [
          FutureBuilder(
            future: listProduct,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return CircularProgressIndicator();
              }

              if (snapshot.hasError) {
                return Text("Error: ${snapshot.error}");
              }

              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return Text("Tidak ada data");
              }

              final products = snapshot.data!;

              return Container(
                width: 500,
                padding: EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      products[0].productId
                          .toString(), // atau tampilkan produk pertama
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          // List Customer
          Column(
            spacing: 5,
            children: [
              // Headbar
              Text(
                "Data Customer",
                style: TextStyle(color: Colors.white, fontSize: 22),
              ),

              // Search Data
              Row(
                children: [
                  SizedBox(
                    width: 200,
                    child: TextInput(
                      controller: searchController,
                      context: context,
                      label: "Search",
                    ),
                  ),
                  ElevatedButton(onPressed: () {}, child: Text("New")),
                ],
              ),

              // Widget Card Data
              Container(
                width: 500,
                padding: EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(5000),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "PT. Sejahtera Abadi",
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                    Text("Jl. Marelan Raya No. 1"),
                    Text("Medan"),
                    Text("Phone -"),
                    Text("Faximile -"),
                    Text("PIC"),
                  ],
                ),
              ),
              Container(
                width: 300,
                padding: EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "PT. Abadi",
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                    Text("Jl. Marelan "),
                    Text("Medan"),
                    Text("Phone -"),
                    Text("Faximile -"),
                    Text("PIC"),
                  ],
                ),
              ),
            ],
          ),

          // List Product
          // Column(
          //   children: [
          //     // Headbar
          //     Text("Data Product"),
          //   ],
          // ),
        ],
      ),
    );

    // return Container(
    //   margin: const EdgeInsets.fromLTRB(30, 100, 30, 50),
    //   // margin: const EdgeInsets.all(10),
    //   decoration: BoxDecoration(
    //     color: Colors.white,
    //     borderRadius: BorderRadius.circular(15),
    //     boxShadow: [
    //       BoxShadow(
    //         color: const Color.fromARGB(255, 40, 40, 40),
    //         blurRadius: 5,
    //         spreadRadius: 1,
    //       ),
    //     ],
    //   ),
    //   child: Column(
    //     children: [
    //       Container(
    //         padding: const EdgeInsets.only(left: 30, top: 15, right: 30),
    //         decoration: BoxDecoration(
    //           color: Colors.white,
    //           boxShadow: [
    //             BoxShadow(
    //               color: const Color.fromARGB(255, 227, 227, 227),
    //               blurRadius: 5,
    //               spreadRadius: -2,
    //               offset: Offset(0, 5),
    //             ),
    //           ],
    //           borderRadius: BorderRadius.only(
    //             topLeft: Radius.circular(15),
    //             topRight: Radius.circular(15),
    //           ),
    //         ),
    //         child: Table(
    //           columnWidths: {
    //             0: FlexColumnWidth(1.5),
    //             1: FlexColumnWidth(0.5),
    //             2: FlexColumnWidth(1.5),
    //           },
    //           children: [
    //             TableRow(
    //               children: [
    //                 head("ID"),
    //                 head("Nama Barang"),
    //                 head("Keterangan"),
    //               ],
    //             ),
    //           ],
    //         ),
    //       ),

    // FutureBuilder(
    //   future: listProduct,
    //   builder: (
    //     BuildContext context,
    //     AsyncSnapshot<List<ListProductJson>> snapshot,
    //   ) {
    //     if (ConnectionState == ConnectionState.waiting) {
    //       return const Center(child: CircularProgressIndicator());
    //     } else if (snapshot.hasData && snapshot.data!.isEmpty) {
    //       return const Center(child: Text("No Transaction found"));
    //     } else if (snapshot.hasError) {
    //       return Center(child: Text(snapshot.error.toString()));
    //     } else {
    //       final temp = snapshot.data ?? <ListProductJson>[];
    //       // Sort data reverse
    //       List<ListProductJson> items = temp.reversed.toList();

    //       return SingleChildScrollView(
    //         padding: const EdgeInsets.fromLTRB(30, 7, 30, 30),
    //         child: Table(
    //           columnWidths: {
    //             0: FlexColumnWidth(1.5),
    //             1: FlexColumnWidth(0.5),
    //             2: FlexColumnWidth(1.5),
    //           },
    //           children: [
    //             ...items.map(
    //               (e) => TableRow(
    //                 decoration: BoxDecoration(
    //                   border: Border(
    //                     bottom: BorderSide(
    //                       width: 1,
    //                       color: const Color.fromARGB(255, 208, 208, 208),
    //                     ),
    //                   ),
    //                 ),
    //                 children: [
    //                   Text("ID"),
    //                   Text("Nama Barang"),
    //                   Text("Keterangan"),
    //                 ],
    //               ),
    //             ),
    //           ],
    //         ),
    //       );
    //     }
    //   },
    // ),
    //     ],
    //   ),
    // );
  }

  Widget TextInput({
    required TextEditingController controller,
    required BuildContext context,
    FocusNode? focus,
    FocusNode? nextFocus,
    String? label,
    String? hint,
    bool? validator,
    String? validatorText,
    int? minline = 1,
    int? maxline = 1,
    Icon? suffixIcon,
    TextCapitalization textCapital = TextCapitalization.none,
    TextInputType? textInputType,
    bool expand = false,
    bool border = true,
  }) {
    return Padding(
      padding: const EdgeInsets.only(top: 15),
      child: TextFormField(
        controller: controller,
        focusNode: focus,
        style: TextStyle(color: Colors.white),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: Colors.white),
          floatingLabelStyle: TextStyle(color: Colors.white, fontSize: 14),
          floatingLabelBehavior: FloatingLabelBehavior.auto,
          hintText: hint,
          // hintStyle: TextStyle(
          //   color: Colors.white,
          //   fontWeight: FontWeight.w300,
          // ),
          suffixIcon: suffixIcon,
          suffixIconColor: Colors.white,
          focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(
              // color: const Color.fromARGB(255, 151, 255, 33),
              color: Color(0xFF0080FF),
              width: 1.5,
            ),
            borderRadius: BorderRadius.all(Radius.circular(10)),
          ),
          enabledBorder: OutlineInputBorder(
            borderSide: BorderSide(color: Colors.grey, width: 1),
            borderRadius: BorderRadius.all(Radius.circular(10)),
          ),
          border:
              border
                  ? OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.white, width: 0.1),
                    borderRadius: BorderRadius.all(Radius.circular(10)),
                  )
                  : null,
        ),
        minLines: minline,
        maxLines: maxline,
        expands: expand,
        textCapitalization: textCapital,
        keyboardType: textInputType,
        validator: (value) {
          if (validator != null) {
            if (value == null || value.isEmpty) {
              return validatorText;
            }
            return null;
          }
          return null;
        },
        onFieldSubmitted: (v) {
          FocusScope.of(context).requestFocus(nextFocus);
        },
      ),
    );
  }

  Widget head(String name) {
    return Container(
      // color: Colors.amber,
      padding: const EdgeInsets.only(bottom: 10),
      alignment: Alignment.center,
      child: Text(
        name,
        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
      ),
    );
  }
}
