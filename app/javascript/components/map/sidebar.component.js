import React, { useState, useRef, useEffect } from 'react';
import useOnClickOutside from 'use-onclickoutside';
import cx from 'classnames';
import kebabCase from 'lodash/kebabCase';

function Sidebar(props) {
  const { shop, fields, dispatch, status, labels, userRights } = props;
  const sidebarRef = useRef(null);
  const formRef = useRef(null);
  const [formState, setFormState] = useState({});
  const [showWarning, setShowWarning] = useState(false);

  const formKey = `${status}${shop && (shop.id || shop.temporaryId)}`;

  const close = () => dispatch({ type: 'clickCloseSidebar' });
  useOnClickOutside(sidebarRef, close);
  useEffect(() => {
    setShowWarning(false);
    setFormState({});
  }, [formKey]);

  const onSave = () => {
    if (status === 'deleting' && !formState.details) {
      setShowWarning(true);
      return;
    }
    dispatch({ type: 'clickSave', payload: formState });
  };
  return (
    <aside ref={sidebarRef} className={cx('c-sidebar', { '-visible': shop })}>
      {shop && shop.state && (
        <span
          className={cx('shop-state-tag', {
            [`-${kebabCase(shop.state)}`]: shop.state
          })}
        >
          {labels[`state_${shop.state}`]}
        </span>
      )}
      <div className="sidebar-header">
        <p className="shop-name">{(shop && shop.name) || labels.add_store}</p>
        {status === 'idle' && (
          <button type="button" className="close-button" aria-label="Close" onClick={close}>
            {labels.close}
          </button>
        )}
      </div>
      <div className="sidebar-content">
        {status === 'deleting' && showWarning && (
          <p className="alert alert-warning sidebar-alert">{labels.remove_note}</p>
        )}
        <form key={formKey} className="sidebar-form" ref={formRef}>
          {shop &&
            fields
              .filter(field => (status === 'deleting' ? field.attribute === 'details' : true))
              .map(field => (
                <FormField
                  {...field}
                  key={field.attribute}
                  value={shop[field.attribute]}
                  status={status}
                  id={`shop-${field.attribute}`}
                  onChange={e => {
                    e.persist();
                    setFormState(formState => ({
                      ...formState,
                      [field.attribute]: e.target.value
                    }));
                  }}
                />
              ))}
        </form>
      </div>
      <div className="sidebar-footer">
        <div className="sidebar-footer-wrapper">
          {['creating', 'deleting', 'editing'].includes(status) && (
            <>
              <button
                type="button"
                className="btn btn-outline-secondary mr-2"
                onClick={() => dispatch({ type: 'clickCancel' })}
              >
                {labels.cancel}
              </button>
              {status !== 'deleting' && (
                <button type="button" onClick={onSave} className="btn btn-outline-success">
                  {labels.save}
                </button>
              )}
              {status === 'deleting' && userRights.DELETE_SHOP && (
                <button type="button" onClick={onSave} className="btn btn-outline-danger">
                  {labels.confirm}
                </button>
              )}
            </>
          )}
          {status === 'idle' && shop && ['live', 'waiting_approval'].includes(shop.state) && (
            <>
              {userRights.EDIT_SHOP && (
                <button
                  type="button"
                  className="btn btn-outline-info mr-2"
                  onClick={() => dispatch({ type: 'clickEdit' })}
                >
                  {labels.edit}
                </button>
              )}
              {userRights.DELETE_SHOP && (
                <button
                  type="button"
                  onClick={() => dispatch({ type: 'clickDelete' })}
                  className="btn btn-outline-danger"
                >
                  {labels.delete}
                </button>
              )}
            </>
          )}
        </div>
      </div>
    </aside>
  );
}

function FormField(props) {
  const { id, attribute, readonly, value, type = 'text', label, options, status, onChange } = props;
  const readOnly = readonly || attribute === 'id' || ['idle'].includes(status);
  return (
    <div className="form-group">
      <label className="sidebar-label" htmlFor={id}>
        {label}
      </label>
      {type !== 'textarea' && (type !== 'select' || ['idle', 'deleting'].includes(status)) && (
        <input
          id={id}
          type={type === 'select' ? 'text' : type}
          readOnly={readOnly}
          defaultValue={value && type === 'select' ? options.find(o => o[1] === value)[0] : value}
          className="form-control"
          onChange={onChange}
        />
      )}
      {type === 'textarea' && (
        <textarea
          id={id}
          rows={4}
          readOnly={readOnly}
          defaultValue={value}
          className="form-control"
          onChange={onChange}
        />
      )}
      {type === 'select' && !['idle', 'deleting'].includes(status) && (
        <select
          id={id}
          readOnly={readOnly}
          defaultValue={value || options[0][1]}
          className="form-control"
          onChange={onChange}
        >
          {options.map(option => (
            <option key={option[1]} value={option[1]}>
              {option[0]}
            </option>
          ))}
        </select>
      )}
    </div>
  );
}

export default React.memo(Sidebar);
