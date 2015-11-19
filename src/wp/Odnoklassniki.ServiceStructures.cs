using Microsoft.Phone.Controls;
using System;
using System.Collections.Generic;

// ReSharper disable once CheckNamespace
namespace Odnoklassniki.ServiceStructures
{
    class ConcurrentDictionary<TKey, TValue> : Dictionary<TKey, TValue>
    {
        private readonly object _lockObject = new Object();

        public void SafeAdd(TKey key, TValue value)
        {
            lock (_lockObject)
            {
                base.Add(key, value);
            }
        }

        public bool SafeRemove(TKey key)
        {
            lock (_lockObject)
            {
                return base.Remove(key);
            }
        }

        public TValue SafeGet(TKey key)
        {
            lock (_lockObject)
            {
                return this[key];
            }
        }

    }

    struct CallbackStruct
    {
        public Action<string> OnSuccess;
        public Action<Exception> OnError;
        public PhoneApplicationPage CallbackContext;
    }

    struct AuthCallbackStruct
    {
        public Action OnSuccess;
        public Action<Exception> OnError;
        public PhoneApplicationPage CallbackContext;
        public bool SaveSession;
    }
}
