import 'package:film_maker/ui/features/projects/view_models/projects_view_model.dart';
import 'package:flutter/material.dart';

class ProjectsView extends StatefulWidget {
  const ProjectsView({super.key, required this.viewModel});

  final ProjectsViewModel viewModel;

  @override
  State<ProjectsView> createState() => _ProjectsViewState();
}

class _ProjectsViewState extends State<ProjectsView> {
  @override
  void initState() {
    super.initState();
    widget.viewModel.loadProjects();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Wedding Films')),
      body: ListenableBuilder(
        listenable: widget.viewModel,
        builder: (context, _) {
          if (widget.viewModel.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: widget.viewModel.projects.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final project = widget.viewModel.projects[index];
              return ListTile(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                tileColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                leading: const Icon(Icons.movie_creation_outlined),
                title: Text(project.title),
                subtitle: Text('${project.sceneCount} slides'),
              );
            },
          );
        },
      ),
    );
  }
}
