import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:pluto_grid/pluto_grid.dart';

import 'ui.dart';

class PlutoBaseRow extends StatelessWidget {
  final int rowIdx;
  final PlutoRow row;
  final List<PlutoColumn> columns;
  final PlutoGridStateManager stateManager;
  final bool visibilityLayout;

  const PlutoBaseRow({
    required this.rowIdx,
    required this.row,
    required this.columns,
    required this.stateManager,
    this.visibilityLayout = false,
    super.key,
  });

  bool _checkSameDragRows(PlutoRow draggingRow) {
    final List<PlutoRow> selectedRows =
    stateManager.currentSelectingRows.isNotEmpty
        ? stateManager.currentSelectingRows
        : [draggingRow];

    final end = rowIdx + selectedRows.length;

    for (int i = rowIdx; i < end; i += 1) {
      if (stateManager.refRows[i].key != selectedRows[i - rowIdx].key) {
        return false;
      }
    }

    return true;
  }

  bool _handleOnWillAccept(DragTargetDetails<PlutoRow> details) {
    return !_checkSameDragRows(details.data);
  }

  void _handleOnAccept(DragTargetDetails<PlutoRow> details) async {
    final draggingRows = stateManager.currentSelectingRows.isNotEmpty
        ? stateManager.currentSelectingRows
        : [details.data];

    // Clear drop target indicators
    stateManager.setDragTargetRowIdx(null);
    stateManager.setDragRows([]);

    stateManager.eventManager!.addEvent(
      PlutoGridDragRowsEvent(
        rows: draggingRows,
        targetIdx: rowIdx,
      ),
    );
  }

  PlutoVisibilityLayoutId _makeCell(PlutoColumn column) {
    return PlutoVisibilityLayoutId(
      id: column.field,
      child: PlutoBaseCell(
        key: row.cells[column.field]!.key,
        cell: row.cells[column.field]!,
        column: column,
        rowIdx: rowIdx,
        row: row,
        stateManager: stateManager,
      ),
    );
  }





  @override
  Widget build(BuildContext context) {
    return DragTarget<PlutoRow>(
      onWillAcceptWithDetails: _handleOnWillAccept,
      onAcceptWithDetails: _handleOnAccept,
      onMove: (details) {
        final offset = details.offset;
        final renderBox = context.findRenderObject() as RenderBox;
        final localPosition = renderBox.globalToLocal(offset);
        // Add debug output to check positions
        debugPrint('Local position: $localPosition');
        debugPrint('RenderBox size: ${renderBox.size}');
        final isTopHalf = localPosition.dy < renderBox.size.height / 2;

        stateManager.setDragTargetRowIdx(
          rowIdx,
          isTopHalf: isTopHalf,
        );
      },
      onLeave: (data) {
        stateManager.setDragTargetRowIdx(null);
      },
      builder: (context, candidateData, rejectedData) {
        return _RowContainerWidget(
          stateManager: stateManager,
          rowIdx: rowIdx,
          row: row,
          enableRowColorAnimation:
          stateManager.configuration.style.enableRowColorAnimation,
          key: ValueKey('rowContainer_${row.key}'),
          child: visibilityLayout
              ? PlutoVisibilityLayout(
            key: ValueKey('rowContainer_${row.key}_row'),
            delegate: _RowCellsLayoutDelegate(
              stateManager: stateManager,
              columns: columns,
              textDirection: stateManager.textDirection,
            ),
            scrollController: stateManager.scroll.bodyRowsHorizontal!,
            initialViewportDimension: MediaQuery.of(context).size.width,
            children: columns.map(_makeCell).toList(growable: false),
          )
              : CustomMultiChildLayout(
            key: ValueKey('rowContainer_${row.key}_row'),
            delegate: _RowCellsLayoutDelegate(
              stateManager: stateManager,
              columns: columns,
              textDirection: stateManager.textDirection,
            ),
            children: columns.map(_makeCell).toList(growable: false),
          ),
        );
      },
    );
  }
}

class _RowCellsLayoutDelegate extends MultiChildLayoutDelegate {
  final PlutoGridStateManager stateManager;
  final List<PlutoColumn> columns;
  final TextDirection textDirection;

  _RowCellsLayoutDelegate({
    required this.stateManager,
    required this.columns,
    required this.textDirection,
  }) : super(relayout: stateManager.resizingChangeNotifier);

  @override
  Size getSize(BoxConstraints constraints) {
    final double width = columns.fold(
      0,
          (previousValue, element) => previousValue + element.width,
    );
    return Size(width, stateManager.rowHeight);
  }

  @override
  void performLayout(Size size) {
    double dx = 0;

    // Always layout columns in their original order regardless of text direction
    // The text direction should be handled by the parent widget's directionality
    for (final column in columns) {
      final width = column.width;

      if (hasChild(column.field)) {
        layoutChild(
          column.field,
          BoxConstraints.tightFor(
            width: width,
            height: stateManager.rowHeight,
          ),
        );

        positionChild(
          column.field,
          Offset(dx, 0),
        );
      }

      dx += width;
    }
  }

  @override
  bool shouldRelayout(covariant MultiChildLayoutDelegate oldDelegate) {
    return true;
  }
}

class _RowContainerWidget extends PlutoStatefulWidget {
  final PlutoGridStateManager stateManager;
  final int rowIdx;
  final PlutoRow row;
  final bool enableRowColorAnimation;
  final Widget child;

  const _RowContainerWidget({
    required this.stateManager,
    required this.rowIdx,
    required this.row,
    required this.enableRowColorAnimation,
    required this.child,
    super.key,
  });

  @override
  State<_RowContainerWidget> createState() => _RowContainerWidgetState();
}

class _RowContainerWidgetState extends PlutoStateWithChange<_RowContainerWidget>
    with AutomaticKeepAliveClientMixin, PlutoStateWithKeepAlive<_RowContainerWidget> {
  @override
  void dispose() {
    if (widget.stateManager.isRowHovered(widget.row)) {
      widget.stateManager.clearHoveredRow();
    }
    super.dispose();
  }

  @override
  PlutoGridStateManager get stateManager => widget.stateManager;

  BoxDecoration _decoration = const BoxDecoration();

  Color get _oddRowColor => stateManager.configuration.style.oddRowColor == null
      ? stateManager.configuration.style.rowColor
      : stateManager.configuration.style.oddRowColor!;

  Color get _evenRowColor =>
      stateManager.configuration.style.evenRowColor == null
          ? stateManager.configuration.style.rowColor
          : stateManager.configuration.style.evenRowColor!;

  @override
  void initState() {
    super.initState();
    updateState(PlutoNotifierEventForceUpdate.instance);
  }

  @override
  void updateState(PlutoNotifierEvent event) {
    _decoration = update<BoxDecoration>(
      _decoration,
      _getBoxDecoration(),
    );

    setKeepAlive(stateManager.isSelecting &&
        stateManager.currentRowIdx == widget.rowIdx);
  }

  Color _getDefaultRowColor() {
    if (stateManager.rowColorCallback == null) {
      return widget.rowIdx % 2 == 0 ? _oddRowColor : _evenRowColor;
    }

    return stateManager.rowColorCallback!(
      PlutoRowColorContext(
        rowIdx: widget.rowIdx,
        row: widget.row,
        stateManager: stateManager,
      ),
    );
  }

  Color _getRowColor({
    required bool isDragTarget,
    required bool isFocusedCurrentRow,
    required bool isSelecting,
    required bool hasCurrentSelectingPosition,
    required bool isCheckedRow,
  }) {
    Color color = _getDefaultRowColor();

    if (isDragTarget) {
      color = stateManager.configuration.style.cellColorInReadOnlyState;
    } else {
      final bool checkCurrentRow = !stateManager.selectingMode.isRow &&
          isFocusedCurrentRow &&
          (!isSelecting && !hasCurrentSelectingPosition);

      final bool checkSelectedRow = stateManager.selectingMode.isRow &&
          stateManager.isSelectedRow(widget.row.key);

      if (checkCurrentRow || checkSelectedRow) {
        color = stateManager.configuration.style.activatedColor;
      }
    }

    if (stateManager.isRowHovered(widget.row) &&
        stateManager.configuration.enableRowHoverColor) {
      color = Color.alphaBlend(
        stateManager.configuration.style.rowHoverColor,
        color,
      );
    }

    return isCheckedRow
        ? Color.alphaBlend(stateManager.configuration.style.checkedColor, color)
        : color;
  }

  BoxDecoration _getBoxDecoration() {
    final bool isCurrentRow = stateManager.currentRowIdx == widget.rowIdx;
    final bool isSelecting = stateManager.isSelecting;
    final bool isCheckedRow = widget.row.checked == true;
    final alreadyTarget = stateManager.dragRows
        .firstWhereOrNull((element) => element.key == widget.row.key) !=
        null;
    final isDraggingRow = stateManager.isDraggingRow;
    final bool isDragTarget = isDraggingRow &&
        !alreadyTarget &&
        stateManager.isRowIdxDragTarget(widget.rowIdx);
    final bool isTopDragTarget =
        isDraggingRow && stateManager.isRowIdxTopDragTarget(widget.rowIdx);
    final bool isBottomDragTarget =
        isDraggingRow && stateManager.isRowIdxBottomDragTarget(widget.rowIdx);
    final bool hasCurrentSelectingPosition =
        stateManager.hasCurrentSelectingPosition;
    final bool isFocusedCurrentRow = isCurrentRow && stateManager.hasFocus;

    final Color rowColor = _getRowColor(
      isDragTarget: isDragTarget,
      isFocusedCurrentRow: isFocusedCurrentRow,
      isSelecting: isSelecting,
      hasCurrentSelectingPosition: hasCurrentSelectingPosition,
      isCheckedRow: isCheckedRow,
    );

    final bool isSelectedRow = stateManager.selectingMode.isRow &&
        stateManager.isSelectedRow(widget.row.key);
    final bool showSelectedBorder = stateManager
        .configuration.style.enableSelectedRowBorder &&
        (isSelectedRow || (isCurrentRow && !stateManager.selectingMode.isRow));

    final BorderSide topBorder = isTopDragTarget
        ? BorderSide(
      width: stateManager.configuration.style.dragTargetIndicatorThickness,
      color: stateManager.configuration.style.dragTargetIndicatorColor,
    )
        : showSelectedBorder
        ? BorderSide(
      width: PlutoGridSettings.rowBorderWidth,
      color: stateManager.configuration.style.selectedRowBorderColor,
    )
        : BorderSide.none;

    final BorderSide bottomBorder = isBottomDragTarget
        ? BorderSide(
      width: stateManager.configuration.style.dragTargetIndicatorThickness,
      color: stateManager.configuration.style.dragTargetIndicatorColor,
    )
        : stateManager.configuration.style.enableCellBorderHorizontal
        ? BorderSide(
      width: PlutoGridSettings.rowBorderWidth,
      color: showSelectedBorder
          ? stateManager.configuration.style.selectedRowBorderColor
          : stateManager.configuration.style.borderColor,
    )
        : showSelectedBorder
        ? BorderSide(
      width: PlutoGridSettings.rowBorderWidth,
      color:
      stateManager.configuration.style.selectedRowBorderColor,
    )
        : BorderSide.none;

    return BoxDecoration(
      color: rowColor,
      border: Border(
        top: topBorder,
        bottom: bottomBorder,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final style = stateManager.configuration.style;

    return MouseRegion(
      onEnter: (_) {
        if (widget.stateManager.configuration.enableRowHoverColor) {
          widget.stateManager.setHoveredRow(widget.row);
        }
      },
      onExit: (_) {
        if (widget.stateManager.configuration.enableRowHoverColor) {
          widget.stateManager.clearHoveredRow();
        }
      },
      child: Stack(
        children: [
          _AnimatedOrNormalContainer(
            enable: widget.enableRowColorAnimation,
            decoration: _getBoxDecoration(),
            child: widget.child,
          ),
          if (stateManager.isRowIdxDragTarget(widget.rowIdx))
            Positioned(
              left: style.dragTargetIndicatorPadding.left,
              right: style.dragTargetIndicatorPadding.right,
              top: stateManager.isRowIdxTopDragTarget(widget.rowIdx)
                  ? style.dragTargetIndicatorPadding.top
                  : null,
              bottom: stateManager.isRowIdxBottomDragTarget(widget.rowIdx)
                  ? style.dragTargetIndicatorPadding.bottom
                  : null,
              child: Container(
                height: style.dragTargetIndicatorThickness,
                color: style.dragTargetIndicatorColor,
              ),
            ),
        ],
      ),
    );
  }
}

class _AnimatedOrNormalContainer extends StatelessWidget {
  final bool enable;
  final Widget child;
  final BoxDecoration decoration;

  const _AnimatedOrNormalContainer({
    required this.enable,
    required this.child,
    required this.decoration,
  });

  @override
  Widget build(BuildContext context) {
    return enable
        ? AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      decoration: decoration,
      child: child,
    )
        : DecoratedBox(decoration: decoration, child: child);
  }
}