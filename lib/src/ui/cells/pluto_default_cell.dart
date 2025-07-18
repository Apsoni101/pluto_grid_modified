import 'dart:async';

import 'package:flutter/material.dart';
import 'package:pluto_grid/pluto_grid.dart';

import '../ui.dart';

typedef DragUpdatedCallback = Function(Offset offset);

class PlutoDefaultCell extends PlutoStatefulWidget {
  final PlutoCell cell;

  final PlutoColumn column;

  final int rowIdx;

  final PlutoRow row;

  final PlutoGridStateManager stateManager;

  const PlutoDefaultCell({
    required this.cell,
    required this.column,
    required this.rowIdx,
    required this.row,
    required this.stateManager,
    super.key,
  });

  @override
  State<PlutoDefaultCell> createState() => _PlutoDefaultCellState();
}

class _PlutoDefaultCellState extends PlutoStateWithChange<PlutoDefaultCell> {
  bool _hasFocus = false;

  bool _canRowDrag = false;

  bool _isCurrentCell = false;

  String _text = '';

  @override
  PlutoGridStateManager get stateManager => widget.stateManager;

  bool get _canExpand {
    if (!widget.row.type.isGroup || !stateManager.enabledRowGroups) {
      return false;
    }

    return _isExpandableCell;
  }

  bool get _isExpandableCell =>
      stateManager.rowGroupDelegate!.isExpandableCell(widget.cell);

  bool get _showSpacing {
    if (!stateManager.enabledRowGroups ||
        !stateManager.rowGroupDelegate!.showFirstExpandableIcon) {
      return false;
    }

    if (_canExpand) return true;

    final parentCell = widget.row.parent?.cells[widget.column.field];

    return parentCell != null &&
        stateManager.rowGroupDelegate!.isExpandableCell(parentCell);
  }

  bool get _isEmptyGroup => widget.row.type.group.children.isEmpty;

  bool get _showGroupCount =>
      stateManager.enabledRowGroups &&
          _isExpandableCell &&
          widget.row.type.isGroup &&
          stateManager.rowGroupDelegate!.showCount;

  String get _groupCount => _compactCount
      ? stateManager.rowGroupDelegate!
      .compactNumber(widget.row.type.group.children.length)
      : widget.row.type.group.children.length.toString();

  bool get _compactCount => stateManager.rowGroupDelegate!.enableCompactCount;

  @override
  void initState() {
    super.initState();

    updateState(PlutoNotifierEventForceUpdate.instance);
  }

  @override
  void updateState(PlutoNotifierEvent event) {
    _hasFocus = update<bool>(
      _hasFocus,
      stateManager.hasFocus,
    );

    _canRowDrag = update<bool>(
      _canRowDrag,
      widget.column.enableRowDrag && stateManager.canRowDrag,
    );

    _isCurrentCell = update<bool>(
      _isCurrentCell,
      stateManager.isCurrentCell(widget.cell),
    );

    _text = update<String>(
      _text,
      widget.column.formattedValueForDisplay(widget.cell.value),
    );
  }

  void _handleToggleExpandedRowGroup() {
    stateManager.toggleExpandedRowGroup(
      rowGroup: widget.row,
    );
  }

  @override
  Widget build(BuildContext context) {
    final cellWidget = _DefaultCellWidget(
      stateManager: stateManager,
      rowIdx: widget.rowIdx,
      row: widget.row,
      column: widget.column,
      cell: widget.cell,
    );

    final style = stateManager.configuration.style;

    Widget? spacingWidget;
    if (_showSpacing) {
      if (widget.row.depth > 0) {
        double gap = style.iconSize * 1.5;
        double spacing = widget.row.depth * gap;
        if (!widget.row.type.isGroup) spacing += gap;
        spacingWidget = SizedBox(width: spacing);
      }
    }

    Widget? expandIcon;
    if (_canExpand) {
      expandIcon = IconButton(
        onPressed: _isEmptyGroup ? null : _handleToggleExpandedRowGroup,
        icon: _isEmptyGroup
            ? Icon(
          style.rowGroupEmptyIcon,
          size: style.iconSize / 2,
          color: style.iconColor,
        )
            : widget.row.type.group.expanded
            ? Icon(
          style.rowGroupExpandedIcon,
          size: style.iconSize,
          color: style.iconColor,
        )
            : Icon(
          style.rowGroupCollapsedIcon,
          size: style.iconSize,
          color: style.iconColor,
        ),
      );
    }

    return Row(children: [
      if (_canRowDrag)
        _RowDragIconWidget(
          column: widget.column,
          row: widget.row,
          rowIdx: widget.rowIdx,
          stateManager: stateManager,
          feedbackWidget: cellWidget,
          dragIcon: Icon(
            Icons.drag_indicator,
            size: style.iconSize,
            color: style.iconColor,
          ),
        ),
      if (widget.column.enableRowChecked)
        CheckboxSelectionWidget(
          column: widget.column,
          row: widget.row,
          rowIdx: widget.rowIdx,
          stateManager: stateManager,
        ),
      if (spacingWidget != null) spacingWidget,
      if (expandIcon != null) expandIcon,
      Expanded(child: cellWidget),
      if (_showGroupCount)
        Text(
          '($_groupCount)',
          style: stateManager.configuration.style.cellTextStyle.copyWith(
            decoration: TextDecoration.none,
            fontWeight: FontWeight.normal,
          ),
        ),
    ]);
  }
}

class _RowDragIconWidget extends StatelessWidget {
  final PlutoColumn column;
  final PlutoRow row;
  final int rowIdx;
  final PlutoGridStateManager stateManager;
  final Widget dragIcon;
  final Widget feedbackWidget;

  const _RowDragIconWidget({
    required this.column,
    required this.row,
    required this.rowIdx,
    required this.stateManager,
    required this.dragIcon,
    required this.feedbackWidget,
  });

  double get rowHeight => stateManager.rowHeight;

  List<PlutoRow> get _draggingRows {
    if (stateManager.currentSelectingRows.isEmpty) {
      return [row];
    }
    if (stateManager.isSelectedRow(row.key)) {
      return stateManager.currentSelectingRows;
    }
    stateManager.clearCurrentSelecting(notify: false);
    return [row];
  }

  Widget _buildRowFeedback() {
    final style = stateManager.configuration.style;
    final visibleColumns = stateManager.columns.where((e) => !e.hide).toList();
    final totalWidth = visibleColumns.fold<double>(0.0, (sum, column) {
      final columnWidth = column.width ?? 0.0;
      return sum + columnWidth;
    });
    return Container(
      constraints: BoxConstraints(
        maxWidth: totalWidth,
        minWidth: totalWidth,
      ),
      height: rowHeight,
      decoration: BoxDecoration(
        color: style.gridBackgroundColor,
        borderRadius: BorderRadius.circular(4),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 10,
            spreadRadius: 2,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const NeverScrollableScrollPhysics(),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: visibleColumns.map((column) {
            final cell = row.cells[column.field]!;
            return SizedBox(
              width: column.width,
              height: rowHeight,
              child: Padding(
                padding: column.cellPadding ?? style.defaultCellPadding,
                child: Align(
                  alignment: column.textAlign.alignmentValue,
                  child: Text(
                    cell.value.toString(),
                    style: style.cellTextStyle.copyWith(
                      fontWeight: FontWeight.bold,
                      decoration: TextDecoration.none,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                    softWrap: false,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Draggable<PlutoRow>(
      data: row,
      dragAnchorStrategy: (draggable, context, position) {
        final renderBox = context.findRenderObject() as RenderBox;
        final localPosition = renderBox.globalToLocal(position);
        return Offset(localPosition.dx, rowHeight / 2);
      },
      feedback: _buildRowFeedback(),
      child: MouseRegion(
        cursor: SystemMouseCursors.grab,
        child: dragIcon,
      ),
      onDragStarted: () {
        stateManager.setIsDraggingRow(true);
        stateManager.setDragRows(_draggingRows);
      },
      onDragEnd: (details) {
        stateManager.setIsDraggingRow(false);
        stateManager.setDragTargetRowIdx(null);
        stateManager.setDragRows([]);
      },
      onDragUpdate: (details) {
        final offset = details.globalPosition;
        stateManager.eventManager!.addEvent(PlutoGridScrollUpdateEvent(
          offset: offset,
        ));
        int? targetRowIdx = stateManager.getRowIdxByOffset(offset.dy);
        stateManager.setDragTargetRowIdx(targetRowIdx);
      },
    );
  }
}

class CheckboxSelectionWidget extends PlutoStatefulWidget {
  final PlutoGridStateManager stateManager;

  final PlutoColumn column;

  final PlutoRow row;

  final int rowIdx;

  const CheckboxSelectionWidget({
    required this.stateManager,
    required this.column,
    required this.row,
    required this.rowIdx,
    super.key,
  });

  @override
  CheckboxSelectionWidgetState createState() => CheckboxSelectionWidgetState();
}

class CheckboxSelectionWidgetState
    extends PlutoStateWithChange<CheckboxSelectionWidget> {
  bool _tristate = false;

  bool? _checked;

  @override
  PlutoGridStateManager get stateManager => widget.stateManager;

  @override
  void initState() {
    super.initState();

    updateState(PlutoNotifierEventForceUpdate.instance);
  }

  @override
  void updateState(PlutoNotifierEvent event) {
    _tristate = update<bool>(
      _tristate,
      stateManager.enabledRowGroups && widget.row.type.isGroup,
    );

    _checked = update<bool?>(
      _checked,
      _tristate ? widget.row.checked : widget.row.checked == true,
    );
  }

  void _handleOnChanged(bool? changed) {
    if (changed == _checked) {
      return;
    }

    if (_tristate) {
      changed ??= false;

      if (_checked == null) changed = true;
    } else {
      changed = changed == true;
    }

    stateManager.setRowChecked(widget.row, changed);

    if (stateManager.onRowChecked != null) {
      stateManager.onRowChecked!(
        PlutoGridOnRowCheckedOneEvent(
          row: widget.row,
          rowIdx: widget.rowIdx,
          isChecked: changed,
        ),
      );
    }

    setState(() {
      _checked = changed;
    });
  }

  @override
  Widget build(BuildContext context) {
    return PlutoScaledCheckbox(
      value: _checked,
      handleOnChanged: _handleOnChanged,
      tristate: _tristate,
      scale: 0.86,
      unselectedColor: stateManager.configuration.style.iconColor,
      activeColor: stateManager.configuration.style.activatedBorderColor,
      checkColor: stateManager.configuration.style.activatedColor,
    );
  }
}
// In pluto_default_cell.dart, modify the _DefaultCellWidget class:
class _DefaultCellWidget extends StatelessWidget {
  final PlutoGridStateManager stateManager;
  final int rowIdx;
  final PlutoRow row;
  final PlutoColumn column;
  final PlutoCell cell;

  const _DefaultCellWidget({
    required this.stateManager,
    required this.rowIdx,
    required this.row,
    required this.column,
    required this.cell,
  });

  bool get _showText {
    if (!stateManager.enabledRowGroups) {
      return true;
    }
    return stateManager.rowGroupDelegate!.isExpandableCell(cell) ||
        stateManager.rowGroupDelegate!.isEditableCell(cell);
  }

  String get _text {
    if (!_showText) return '';

    dynamic cellValue = cell.value;

    if (stateManager.enabledRowGroups &&
        stateManager.rowGroupDelegate!.showFirstExpandableIcon &&
        stateManager.rowGroupDelegate!.type.isByColumn) {
      final delegate =
      stateManager.rowGroupDelegate as PlutoRowGroupByColumnDelegate;

      if (row.depth < delegate.columns.length) {
        cellValue = row.cells[delegate.columns[row.depth].field]!.value;
      }
    }

    return column.formattedValueForDisplay(cellValue);
  }

  Widget _buildMainContent() {
    if (cell.widget != null && cell.value != null) {
      return Row(
        children: [
          Expanded(
            child: Text(
              _text,
              style: stateManager.configuration.style.cellTextStyle.copyWith(
                decoration: TextDecoration.none,
                fontWeight: FontWeight.normal,
              ),
              overflow: TextOverflow.ellipsis,
              textAlign: column.textAlign.value,
            ),
          ),
          const SizedBox(width: 8),
          cell.widget!,
        ],
      );
    } else if (cell.widget != null) {
      return cell.widget!;
    }

    return Text(
      _text,
      style: stateManager.configuration.style.cellTextStyle.copyWith(
        decoration: TextDecoration.none,
        fontWeight: FontWeight.normal,
      ),
      overflow: TextOverflow.ellipsis,
      textAlign: column.textAlign.value,
    );
  }

  @override
  Widget build(BuildContext context) {
    // Custom renderer takes highest priority
    if (column.hasRenderer) {
      return column.renderer!(PlutoColumnRendererContext(
        column: column,
        rowIdx: rowIdx,
        row: row,
        cell: cell,
        stateManager: stateManager,
      ));
    }

    final mainContent = _buildMainContent();

    return Row(
      children: [
        if (column.hasDragHandle)
          _RowDragIconWidget(
            column: column,
            row: row,
            rowIdx: rowIdx,
            stateManager: stateManager,
            dragIcon: Icon(
              Icons.drag_handle,
              size: stateManager.configuration.style.iconSize,
              color: stateManager.configuration.style.iconColor,
            ),
            feedbackWidget: mainContent,
          ),
        Expanded(child: mainContent),
      ],
    );
  }
}