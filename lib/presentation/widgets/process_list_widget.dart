import 'package:flutter/material.dart';
import '../../domain/models/process_info.dart';
import '../dashboard/process_detail_view.dart';

enum SortColumn { name, pid, user, cpu, mem }

class ProcessListWidget extends StatefulWidget {
  final List<ProcessInfo> processes;

  const ProcessListWidget({super.key, required this.processes});

  @override
  State<ProcessListWidget> createState() => _ProcessListWidgetState();
}

class _ProcessListWidgetState extends State<ProcessListWidget> {
  String _searchQuery = '';
  SortColumn _sortColumn = SortColumn.cpu;
  bool _sortAscending = false;

  @override
  Widget build(BuildContext context) {
    // Filter
    var filtered = widget.processes.where((p) {
      if (_searchQuery.isEmpty) return true;
      return p.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          p.user.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          p.pid.toString().contains(_searchQuery);
    }).toList();

    // Sort
    filtered.sort((a, b) {
      int res = 0;
      switch (_sortColumn) {
        case SortColumn.name:
          res = a.name.compareTo(b.name);
          break;
        case SortColumn.pid:
          res = a.pid.compareTo(b.pid);
          break;
        case SortColumn.user:
          res = a.user.compareTo(b.user);
          break;
        case SortColumn.cpu:
          res = a.cpuUsagePercentage.compareTo(b.cpuUsagePercentage);
          break;
        case SortColumn.mem:
          res = a.memoryUsageBytes.compareTo(b.memoryUsageBytes);
          break;
      }
      return _sortAscending ? res : -res;
    });

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: TextField(
            decoration: const InputDecoration(
              hintText: 'Search PID, Name, or User...',
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(),
              isDense: true,
            ),
            onChanged: (val) => setState(() => _searchQuery = val),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          color: Theme.of(context).cardColor.withValues(alpha: 0.5),
          child: Row(
            children: [
              Expanded(
                flex: 3,
                child: _buildSortHeader('Name', SortColumn.name),
              ),
              Expanded(flex: 1, child: _buildSortHeader('PID', SortColumn.pid)),
              Expanded(
                flex: 1,
                child: _buildSortHeader('User', SortColumn.user),
              ),
              Expanded(
                flex: 1,
                child: _buildSortHeader('CPU %', SortColumn.cpu),
              ),
              Expanded(flex: 1, child: _buildSortHeader('Mem', SortColumn.mem)),
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: ListView.builder(
            itemCount: filtered.length > 200 ? 200 : filtered.length,
            itemBuilder: (ctx, i) {
              final proc = filtered[i];
              return InkWell(
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (ctx) => ProcessDetailView(pid: proc.pid),
                    ),
                  );
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: Text(proc.name, overflow: TextOverflow.ellipsis),
                      ),
                      Expanded(flex: 1, child: Text(proc.pid.toString())),
                      Expanded(
                        flex: 1,
                        child: Text(proc.user, overflow: TextOverflow.ellipsis),
                      ),
                      Expanded(
                        flex: 1,
                        child: Text(
                          '${proc.cpuUsagePercentage.toStringAsFixed(1)}%',
                        ),
                      ),
                      Expanded(
                        flex: 1,
                        child: Text(
                          '${(proc.memoryUsageBytes / (1024 * 1024)).toStringAsFixed(1)}M',
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSortHeader(String title, SortColumn col) {
    return InkWell(
      onTap: () {
        setState(() {
          if (_sortColumn == col) {
            _sortAscending = !_sortAscending;
          } else {
            _sortColumn = col;
            _sortAscending = false;
          }
        });
      },
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(
            child: Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (_sortColumn == col)
            Icon(
              _sortAscending ? Icons.arrow_upward : Icons.arrow_downward,
              size: 14,
            ),
        ],
      ),
    );
  }
}
