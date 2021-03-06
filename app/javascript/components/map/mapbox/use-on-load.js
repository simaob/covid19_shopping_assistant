import { useEffect, useState } from 'react';

export function useOnLoad(onLoad = () => {}, payload) {
  const [loaded, setLoaded] = useState(false);
  useEffect(() => {
    if (loaded) {
      return onLoad(payload);
    }
  }, [loaded, payload]);

  return [loaded, setLoaded];
}
