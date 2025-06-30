import 'package:flutter/material.dart';
import 'package:pluto_grid/pluto_grid.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Stock Watchlist',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(),
      home: const PlutoGridWatchlistPage(),
    );
  }
}

class PlutoGridWatchlistPage extends StatefulWidget {
  const PlutoGridWatchlistPage({super.key});

  @override
  State<PlutoGridWatchlistPage> createState() => _PlutoGridWatchlistPageState();
}

class _PlutoGridWatchlistPageState extends State<PlutoGridWatchlistPage> {
  final List<PlutoColumn> columns = [
    PlutoColumn(
        title: 'Symbol',
        field: 'symbol',
        enableRowDrag: true,
        enableColumnDrag: true,
        type: PlutoColumnType.text(),
        frozen: PlutoColumnFrozen.start,

        ),
    PlutoColumn(
      title: 'Company',
      field: 'company',
      type: PlutoColumnType.text(),
      frozen: PlutoColumnFrozen.start,
    ),
    PlutoColumn(
        title: 'Bid qty', field: 'bid_qty', type: PlutoColumnType.number()),
    PlutoColumn(
        title: 'Bid rate', field: 'bid_rate', type: PlutoColumnType.currency()),
    PlutoColumn(
        title: 'Ask qty', field: 'ask_qty', type: PlutoColumnType.number()),
    PlutoColumn(
        title: 'Ask rate', field: 'ask_rate', type: PlutoColumnType.currency()),
    PlutoColumn(
      title: 'Volume',
      field: 'volume',
      type: PlutoColumnType.number(),
    ),
    PlutoColumn(
      title: '52W High',
      field: 'high_52w',
      type: PlutoColumnType.currency(),
    ),
    PlutoColumn(
      title: '52W Low',
      field: 'low_52w',
      type: PlutoColumnType.currency(),
    ),
    PlutoColumn(
        title: 'LTP',
        field: 'ltp',
        type: PlutoColumnType.currency(),
        cellColor: (value) {
          if (value is num && value > 0) return Colors.green[800];
          if (value is num && value < 0) return Colors.red[800];
          return null;
        }),
    PlutoColumn(
      title: 'Net Change',
      field: 'change',
      type: PlutoColumnType.text(),
      cellColor: (value) {
        if ((value as String).contains('+')) return Colors.green[900];
        if (value.contains('-')) return Colors.red[900];
        return null;
      },
    ),
  ];

  final List<PlutoRow> rows = [
    PlutoRow(cells: {
      'symbol': PlutoCell(value: 'TATACOMM'),
      'company': PlutoCell(value: 'Tata Communications'),
      'bid_qty': PlutoCell(value: 47),
      'bid_rate': PlutoCell(value: 1673.5),
      'ask_qty': PlutoCell(value: 6),
      'ask_rate': PlutoCell(value: 1674.7),
      'volume': PlutoCell(value: 125000),
      'high_52w': PlutoCell(value: 1850.0),
      'low_52w': PlutoCell(value: 1200.0),
      'ltp': PlutoCell(value: 1680.8),
      'change': PlutoCell(value: '+2.30 (+0.14%)'),
    }),
    PlutoRow(cells: {
      'symbol': PlutoCell(value: 'BIRLACORPN'),
      'company': PlutoCell(
        value: 'Birla Corporation',
      ),
      'bid_qty': PlutoCell(value: 222),
      'bid_rate': PlutoCell(value: 1341.8),
      'ask_qty': PlutoCell(value: 130),
      'ask_rate': PlutoCell(value: 1343.2),
      'volume': PlutoCell(value: 98000),
      'high_52w': PlutoCell(value: 1500.0),
      'low_52w': PlutoCell(value: 1000.0),
      'ltp': PlutoCell(value: 1335.5),
      'change': PlutoCell(value: '+4.10 (+0.31%)'),
    }),
    PlutoRow(cells: {
      'symbol': PlutoCell(value: 'TATACONSUM'),
      'company': PlutoCell(value: 'Tata Consumer'),
      'bid_qty': PlutoCell(value: 221),
      'bid_rate': PlutoCell(value: 1099.4),
      'ask_qty': PlutoCell(value: 452),
      'ask_rate': PlutoCell(value: 1101.5),
      'volume': PlutoCell(value: 150000),
      'high_52w': PlutoCell(value: 1250.0),
      'low_52w': PlutoCell(value: 950.0),
      'ltp': PlutoCell(value: 1098.6),
      'change': PlutoCell(value: '-25.50 (-2.27%)'),
    }),
    PlutoRow(cells: {
      'symbol': PlutoCell(value: 'ACCEL'),
      'company': PlutoCell(value: 'Accel Ltd'),
      'bid_qty': PlutoCell(value: 189),
      'bid_rate': PlutoCell(value: 16.14),
      'ask_qty': PlutoCell(value: 48),
      'ask_rate': PlutoCell(value: 16.39),
      'volume': PlutoCell(value: 50000),
      'high_52w': PlutoCell(value: 20.0),
      'low_52w': PlutoCell(value: 12.0),
      'ltp': PlutoCell(value: 16.39),
      'change': PlutoCell(value: '-0.10 (-0.61%)'),
    }),
    PlutoRow(cells: {
      'symbol': PlutoCell(value: 'TATVA-EQ'),
      'company': PlutoCell(value: 'Tatva Chintan Pharma'),
      'bid_qty': PlutoCell(value: 16),
      'bid_rate': PlutoCell(value: 957.5),
      'ask_qty': PlutoCell(value: 3),
      'ask_rate': PlutoCell(value: 959.85),
      'volume': PlutoCell(value: 75000),
      'high_52w': PlutoCell(value: 1100.0),
      'low_52w': PlutoCell(value: 800.0),
      'ltp': PlutoCell(value: 959),
      'change': PlutoCell(value: '+15.75 (+1.67%)'),
    }),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Container(
          padding: const EdgeInsets.all(12),
          child: PlutoGrid(
            columns: columns,
            rows: rows,
            onLoaded: (event) {
              event.stateManager.setShowColumnFilter(true);
            },
            configuration: const PlutoGridConfiguration(
              enableRowHoverColor: true,
              style: PlutoGridStyleConfig.dark(
                gridBackgroundColor: Color(0xFF121212),
                cellTextStyle: TextStyle(color: Colors.white, fontSize: 13),
                columnTextStyle: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
                rowColor: Colors.transparent,
                activatedColor: Color(0xFF1E1E1E),
                borderColor: Colors.transparent,
                gridBorderColor: Colors.transparent,
                enableCellBorderVertical: false,
                rowHeight: 45,
                columnHeight: 42,
                columnFilterHeight: 35,
                defaultCellPadding:
                    EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                rowHoverColor: Color(0xFF2A2A2A),
              ),
              enableMoveHorizontalInEditing: true,
              enterKeyAction: PlutoGridEnterKeyAction.editingAndMoveRight,
              scrollbar: PlutoGridScrollbarConfig(
                isAlwaysShown: true,
                scrollbarThickness: 6,
                scrollbarThicknessWhileDragging: 10,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
