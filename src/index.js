import './main.css';
import './vendor/bulma.css';
import { Main } from './Main.elm';
import registerServiceWorker from './registerServiceWorker';
import setupWithAppStorage from './storage';

setupWithAppStorage(Main);

window.addEventListener('beforeinstallprompt', e => {
  e.preventDefault();
  e.prompt();
});

registerServiceWorker();
