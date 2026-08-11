# Offline reading and purchased-book export

- A started catalogue book is saved in the app-private download directory and added to a persistent local shadow of the **Okuduklarım** shelf.
- The reading shelf paints that local shadow immediately offline, then reconciles it with `GET /books/all?my_books=true` when online.
- Subscription access remains constrained by the cached subscription expiry; purchased-book access remains permanent.
- After a successful book purchase, the user can either keep the app-private offline copy only or open the operating system's Files/Downloads/Drive picker to save an additional copy in a chosen location.
- `flutter analyze` completed without errors or warnings. Two pre-existing informational style suggestions remain.
