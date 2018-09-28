require 'test_helper'

require 'hashie'

module Logdb
  module Test
    class HashieTest < ::Test::Unit::TestCase

      context "Hashie" do
        subject { FakeClient.new }

        should "wrap the response" do
          json =<<-JSON
            {
              "total": 7,
              "partialSuccess": false,
              "data": [{
                "timestamp": "2017-06-14T07:22:22+00:00",
                "docker": {
                  "container_id": "5c271c7e2c2ef920e6f8ce087ea3cd34e07253677edef12646b27677f77a843d"
                },
                "kubernetes": {
                  "container_name": "kube-apiserver",
                  "host": "vm-201704171033",
                  "labels": {
                    "component": "kube-apiserver",
                    "tier": "control-plane"
                  },
                  "namespace_name": "kube-system",
                  "pod_id": "6ad22013-4ab0-11e7-85fc-fa163e6109cd",
                  "pod_name": "kube-apiserver-vm-201704171033"
                },
                "log": "I0614 07:22:22.636665       1 compact.go:159] etcd: compacted rev (416635), endpoints ([http://127.0.0.1:2379])",
                "stream": "stderr",
                "tag": "kubernetes.var.log.containers.kube-apiserver-vm-201704171033_kube-system_kube-apiserver-5c271c7e2c2ef920e6f8ce087ea3cd34e07253677edef12646b27677f77a843d.log"
              },
              {
                "timestamp": "2017-06-14T07:23:18+00:00",
                "docker": {
                  "container_id": "5c271c7e2c2ef920e6f8ce087ea3cd34e07253677edef12646b27677f77a843d"
                },
                "kubernetes": {
                  "container_name": "kube-apiserver",
                  "host": "vm-201704171033",
                  "labels": {
                    "component": "kube-apiserver",
                    "tier": "control-plane"
                  },
                  "namespace_name": "kube-system",
                  "pod_id": "6ad22013-4ab0-11e7-85fc-fa163e6109cd",
                  "pod_name": "kube-apiserver-vm-201704171033"
                },
                "log": "E0614 07:23:18.164522       1 watcher.go:188] watch chan error: etcdserver: mvcc: required revision has been compacted",
                "stream": "stderr",
                "tag": "kubernetes.var.log.containers.kube-apiserver-vm-201704171033_kube-system_kube-apiserver-5c271c7e2c2ef920e6f8ce087ea3cd34e07253677edef12646b27677f77a843d.log"
              }]
            }
          JSON

          response = Hashie::Mash.new MultiJson.load(json)

		  assert_equal 'kube-system',               response.data.first.kubernetes.namespace_name
		  assert_equal '2017-06-14T07:22:22+00:00', response.data.first.timestamp
		  assert_equal '2017-06-14T07:22:22+00:00', response.data.first['timestamp']
        end
      end

    end
  end
end
