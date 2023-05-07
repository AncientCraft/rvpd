import 'dart:collection';

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

void main() {
  runApp(
    const ProviderScope(
      child: MyApp(),
    ),
  );
}

@immutable
class Film {
  final String id;
  final String title;
  final String description;
  final bool isFavorite;

  const Film({
    required this.id,
    required this.title,
    required this.description,
    required this.isFavorite,
  });

  Film copy({required bool isFavorite}) => Film(
        id: id,
        title: title,
        description: description,
        isFavorite: isFavorite,
      );

  @override
  String toString() =>
      'Film(id: $id, title: $title, description: $description, isFavorite: $isFavorite)';

  @override
  bool operator ==(covariant Film other) =>
      id == other.id && isFavorite == other.isFavorite;

  @override
  int get hashCode => Object.hashAll(
        [id, isFavorite],
      );
}

const allFilms = [
  Film(
    id: '1',
    title: 'The Shawshank Redemption',
    description: 'Description for The Shawshank Redemption',
    isFavorite: false,
  ),
  Film(
    id: '2',
    title: 'The Godfather',
    description: 'Description for The Godfather',
    isFavorite: false,
  ),
  Film(
    id: '3',
    title: 'The Godfather: Part II',
    description: 'Description for The Godfather: Part II',
    isFavorite: false,
  ),
  Film(
    id: '4',
    title: 'The Dark Knight',
    description: 'Description for The Dark Knight',
    isFavorite: false,
  ),
];

class FilmNotifier extends StateNotifier<List<Film>> {
  FilmNotifier() : super(allFilms);

  void update(Film film, bool isFavorite) {
    state = state
        .map((thisFilm) => thisFilm.id == film.id
            ? thisFilm.copy(isFavorite: isFavorite)
            : thisFilm)
        .toList();
  }
}

enum FavoriteStatus {
  all,
  favorite,
  notFavorite,
}

final favoriteStatusProvider = StateProvider<FavoriteStatus>((ref) {
  return FavoriteStatus.all;
});

final allFilmProvider = StateNotifierProvider<FilmNotifier, List<Film>>((ref) {
  return FilmNotifier();
});

final favoriteFilmProvider = Provider<Iterable<Film>>((ref) {
  return ref.watch(allFilmProvider).where((element) => element.isFavorite);
});

final notFavoriteFilmProvider = Provider<Iterable<Film>>((ref) {
  return ref.watch(allFilmProvider).where((element) => !element.isFavorite);
});

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      darkTheme: ThemeData.dark(),
      themeMode: ThemeMode.dark,
      debugShowCheckedModeBanner: false,
      home: const HomePage(),
    );
  }
}

class HomePage extends ConsumerWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // ref.watch(allFilmProvider.notifier).update
    return Scaffold(
      appBar: AppBar(
        title: const Text('Films'),
      ),
      body: Column(children: [
        const FilterWiget(),
        Consumer(
          builder: (context, ref, child) {
            final filter = ref.watch(favoriteStatusProvider);
            switch (filter) {
              case FavoriteStatus.all:
                return FilmWidget(provider: allFilmProvider);
              case FavoriteStatus.favorite:
                return FilmWidget(provider: favoriteFilmProvider);
              case FavoriteStatus.notFavorite:
                return FilmWidget(provider: notFavoriteFilmProvider);
            }
          },
        ),
      ]),
      // body: FilmPage(provider: allFilmProvider),
    );
  }
}

class FilmWidget extends ConsumerWidget {
  const FilmWidget({
    Key? key,
    required this.provider,
  }) : super(key: key);
  final AlwaysAliveProviderBase<Iterable<Film>> provider;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final films = ref.watch(provider);
    return Expanded(
      child: ListView.builder(
        itemCount: films.length,
        itemBuilder: (context, index) {
          final film = films.elementAt(index);
          final favoriteIcon = film.isFavorite
              ? const Icon(Icons.favorite)
              : const Icon(Icons.favorite_border);
          return ListTile(
            title: Text(film.title),
            subtitle: Text(film.description),
            trailing: IconButton(
              icon: favoriteIcon,
              onPressed: () {
                final isFavorite = !film.isFavorite;
                ref.read(allFilmProvider.notifier).update(
                      film,
                      isFavorite,
                    );
              },
            ),
          );
        },
      ),
    );
  }
}

class FilterWiget extends StatelessWidget {
  const FilterWiget({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (context, ref, child) {
        return DropdownButton(
          value: ref.watch(favoriteStatusProvider),
          items: FavoriteStatus.values
              .map(
                (e) => DropdownMenuItem(
                  value: e,
                  child: Text(e.toString().split('.').last),
                ),
              )
              .toList(),
          onChanged: (FavoriteStatus? value) {
            ref.read(favoriteStatusProvider.notifier).state = value!;
          },
        );
      },
    );
  }
}
