import React from 'react';
import capitalize from 'lodash/capitalize';

function Toolbar(props) {
  const { status, dispatch, labels, userRights } = props;
  const dispatchAction = e => {
    const { actionType } = e.target.dataset;
    dispatch({ type: actionType });
  };

  return (
    <div className="c-toolbar">
      <div className="toolbar-wrapper d-flex justify-content-between align-items-center">
        <div>{status !== 'idle' && <h3 className="toolbar-title">{labels[status]}</h3>}</div>
        <div>
          {status === 'idle' && (
            <>
              {userRights.CREATE_SHOP && (
                <button
                  type="button"
                  className="btn btn-outline-primary mr-2"
                  onClick={dispatchAction}
                  data-action-type="clickAdd"
                >
                  {labels.add_store}
                </button>
              )}
              {userRights.DELETE_SHOP && (
                <button
                  type="button"
                  className="btn btn-outline-danger"
                  onClick={dispatchAction}
                  data-action-type="clickDelete"
                >
                  {labels.delete_store}
                </button>
              )}
            </>
          )}
          {status !== 'idle' && (
            <button
              type="button"
              className="btn btn-outline-secondary mr-2"
              onClick={dispatchAction}
              data-action-type="clickCancel"
            >
              {labels.cancel}
            </button>
          )}
        </div>
      </div>
    </div>
  );
}

export default React.memo(Toolbar);
