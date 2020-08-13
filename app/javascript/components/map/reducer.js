import produce from 'immer';
import { v4 as uuidv4 } from 'uuid';
import { getUserRightsByRole } from './user-rights';

const getMarkerId = payload => {
  return payload.id;
};

export const initialState = {
  status: 'idle',
  shops: {},
  prevShops: null,
  selectedShopId: null,
  method: null,
  bounds: null
};

const onClickCancel = (state, action, draft) => {
  draft.status = 'idle';
  draft.prevShops = initialState.prevShops;
  draft.shops = state.prevShops || initialState.shops;
  draft.selectedShopId = initialState.selectedShopId;
};

const onClickSave = (state, action, draft) => {
  const methods = {
    creating: 'POST',
    editing: 'PUT',
    deleting: 'DELETE'
  };
  draft.method = methods[state.status];
  draft.status = 'saving';
  const shop = draft.shops[state.selectedShopId];
  Object.assign(shop, action.payload);
};

const onDragMarker = (state, action, draft) => {
  const shop = draft.shops[state.selectedShopId];
  shop.longitude = action.payload[0];
  shop.latitude = action.payload[1];
};

const onBoundsChange = (state, action, draft) => {
  const bounds = [...action.payload];
  draft.bounds = bounds;
};

const onShopsFetched = (state, action, draft) => {
  const temporaryShops = Object.values(draft.shops).filter(
    shop => typeof shop.id === 'undefined' && typeof shop.temporaryId !== 'undefined'
  );
  draft.shops = { ...action.payload };

  // don't remove newly created stores
  temporaryShops.forEach(shop => {
    draft.shops[shop.temporaryId] = shop;
  });
};

export function idleStatus(state, action, draft) {
  switch (action.type) {
    case 'clickAdd': {
      draft.status = 'creating';
      draft.prevShops = state.shops;
      return draft;
    }
    case 'clickDelete': {
      draft.status = 'deleting';
      draft.prevShops = state.shops;
      return draft;
    }
    case 'clickEdit': {
      draft.status = 'editing';
      draft.prevShops = state.shops;
      return draft;
    }
    case 'clickMarker': {
      const id = getMarkerId(action.payload);
      draft.selectedShopId = id === state.selectedShopId ? initialState.selectedShopId : id;
      return draft;
    }
    case 'clickCloseSidebar': {
      draft.selectedShopId = initialState.selectedShopId;
      return draft;
    }
    case 'boundsChange': {
      return onBoundsChange(state, action, draft);
    }
    case 'shopsFetched': {
      return onShopsFetched(state, action, draft);
    }
  }
}

export function creatingStatus(state, action, draft) {
  switch (action.type) {
    case 'clickMap': {
      const { lngLat } = action.payload;
      if (state.selectedShopId && draft.shops) {
        const shop = draft.shops[state.selectedShopId];
        if (shop && shop.temporaryId) {
          delete draft.shops[state.selectedShopId];
        }
      }
      const temporaryId = uuidv4();
      let fields = {};
      if (Object.keys(state.shops).length > 0) {
        const first = Object.values(state.shops)[0];
        fields = Object.keys(first).reduce((acc, next) => {
          if (next === 'id') {
            return acc;
          }
          return { ...acc, [next]: '' };
        }, {});
      }
      draft.shops[temporaryId] = {
        ...fields,
        temporaryId,
        longitude: lngLat[0],
        latitude: lngLat[1]
      };
      draft.selectedShopId = temporaryId;
      return draft;
    }
    case 'dragMarker': {
      return onDragMarker(state, action, draft);
    }
    case 'clickSave': {
      return onClickSave(state, action, draft);
    }
    case 'clickCancel': {
      return onClickCancel(state, action, draft);
    }
    case 'boundsChange': {
      return onBoundsChange(state, action, draft);
    }
    case 'shopsFetched': {
      return onShopsFetched(state, action, draft);
    }
  }
}

export function deletingStatus(state, action, draft) {
  switch (action.type) {
    case 'clickMarker': {
      draft.selectedShopId = getMarkerId(action.payload);
      if (state.shops[draft.selectedShopId].state === 'marked_for_deletion') {
        draft.status = 'idle';
      }
      return draft;
    }
    case 'clickSave': {
      return onClickSave(state, action, draft);
    }
    case 'clickCancel': {
      onClickCancel(state, action, draft);
      draft.selectedShopId = state.selectedShopId;
      return draft;
    }
    case 'boundsChange': {
      return onBoundsChange(state, action, draft);
    }
    case 'shopsFetched': {
      return onShopsFetched(state, action, draft);
    }
  }
}

export function editingStatus(state, action, draft) {
  switch (action.type) {
    case 'dragMarker': {
      return onDragMarker(state, action, draft);
    }
    case 'clickSave': {
      return onClickSave(state, action, draft);
    }
    case 'clickCancel': {
      onClickCancel(state, action, draft);
      draft.selectedShopId = state.selectedShopId;
      return draft;
    }
    case 'boundsChange': {
      return onBoundsChange(state, action, draft);
    }
    case 'shopsFetched': {
      return onShopsFetched(state, action, draft);
    }
  }
}

export function savingStatus(state, action, draft) {
  switch (action.type) {
    case 'saveSuccessful': {
      const shop = { ...action.payload };
      delete draft.shops[state.selectedShopId];
      draft.shops[shop.id] = shop;
      draft.selectedShopId = shop.id;
      draft.status = 'idle';
      return draft;
    }
    case 'saveFailed': {
      const statuses = {
        POST: 'creating',
        PUT: 'editing',
        DELETE: 'deleting'
      };
      draft.status = statuses[state.method];
      draft.method = initialState.method;
      return draft;
    }
    case 'boundsChange': {
      return onBoundsChange(state, action, draft);
    }
    case 'shopsFetched': {
      return onShopsFetched(state, action, draft);
    }
  }
}

const reducer = (state = initialState, action) =>
  produce(state, draft => {
    if (state.status === 'idle') {
      idleStatus(state, action, draft);
    }

    if (state.status === 'creating') {
      creatingStatus(state, action, draft);
    }

    if (state.status === 'deleting') {
      deletingStatus(state, action, draft);
    }

    if (state.status === 'editing') {
      editingStatus(state, action, draft);
    }

    if (state.status === 'saving') {
      savingStatus(state, action, draft);
    }
  });

export default reducer;
