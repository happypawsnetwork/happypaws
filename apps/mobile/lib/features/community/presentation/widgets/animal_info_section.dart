import 'package:flutter/material.dart';

class AnimalInfoSection extends StatelessWidget {
  final String? species;
  final String? name;
  final String? description;

  const AnimalInfoSection({
    super.key,
    this.species,
    this.name,
    this.description,
  });

  @override
  Widget build(BuildContext context) {
    if (species == null && name == null && description == null) {
      return const SizedBox.shrink();
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(Icons.pets),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (name != null || species != null)
                Text(
                  '${name ?? 'Unknown'} (${species ?? 'Unknown'})',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
              if (description != null)
                Text(
                  description!,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
            ],
          ),
        ),
      ],
    );
  }
}
