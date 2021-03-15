# How to delete namesapce stuck in 'Terminating' status

> - Source [StackOverflow](https://stackoverflow.com/questions/55853312/how-to-force-delete-a-kubernetes-namespace)

### Create this JSON with an empty finalizers list:
```sh
~$ cat ns.json

{
  "kind": "Namespace",
  "apiVersion": "v1",
  "metadata": {
    "name": "delete-me"
  },
  "spec": {
    "finalizers": []
  }
}
```

### Use curl to PUT the object without the problematic finalizer.
```sh
~$ curl -k -H "Content-Type: application/json" -X PUT --data-binary @ns.json http://127.0.0.1:8007/api/v1/namespaces/delete-me/finalize

{
  "kind": "Namespace",
  "apiVersion": "v1",
  "metadata": {
    "name": "delete-me",
    "selfLink": "/api/v1/namespaces/delete-me/finalize",
    "uid": "0df02f91-6782-11e9-8beb-42010a800137",
    "resourceVersion": "39047",
    "creationTimestamp": "2019-04-25T17:46:28Z",
    "deletionTimestamp": "2019-04-25T17:46:31Z",
    "annotations": {
      "kubectl.kubernetes.io/last-applied-configuration": "{\"apiVersion\":\"v1\",\"kind\":\"Namespace\",\"metadata\":{\"annotations\":{},\"name\":\"delete-me\"},\"spec\":{\"finalizers\":[\"foregroundDeletion\"]}}\n"
    }
  },
  "spec": {

  },
  "status": {
    "phase": "Terminating"
  }
}
```

### The Namespace is deleted!
```sh~$ kubectl get ns delete-me

Error from server (NotFound): namespaces "delete-me" not found
```
