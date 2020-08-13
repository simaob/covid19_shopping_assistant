import { useMemo } from 'react';

export function getUserRightsByRole(userRole) {
  const rights = {
    CREATE_SHOP: true,
    EDIT_SHOP: false,
    DELETE_SHOP: false
  };

  if (userRole === 'admin') {
    rights.DELETE_SHOP = true;
    rights.EDIT_SHOP = true;
  }
  return rights;
}
export function useUserRights(userRole) {
  return useMemo(() => getUserRightsByRole(userRole), [userRole]);
}
