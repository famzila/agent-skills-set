import { computed } from '@angular/core';
import { signalStore, withState, withComputed, withMethods, patchState } from '@ngrx/signals';

interface AppState {
  count: number;
  loading: boolean;
}

const initialState: AppState = {
  count: 0,
  loading: false,
};

export const AppStore = signalStore(
  { providedIn: 'root' },
  withState(initialState),
  withComputed((state) => ({
    doubleCount: computed(() => state.count() * 2),
  })),
  withMethods((store) => ({
    increment(): void {
      patchState(store, (state) => ({ count: state.count + 1 }));
    },
    decrement(): void {
      patchState(store, (state) => ({ count: state.count - 1 }));
    },
    setLoading(loading: boolean): void {
      patchState(store, { loading });
    },
  })),
);
