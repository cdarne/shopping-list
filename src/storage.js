export default function setupWithAppStorage(main) {
  let storedState = localStorage.getItem('shopping-list-save');
  let startingState = storedState ? JSON.parse(storedState) : [];
  let app = main.fullscreen(startingState);
  app.ports.setStorage.subscribe(function(state) {
    localStorage.setItem('shopping-list-save', JSON.stringify(state));
  });
}
