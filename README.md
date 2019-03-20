# ocbc

hdfs_ssl_server_safety_valve/yarn_ssl_server_safety_valve

<property><name>ssl.server.exclude.cipher.list</name><value>TLS_RSA_WITH_AES_128_GCM_SHA256,TLS_RSA_WITH_AES_128_CBC_SHA256,TLS_RSA_WITH_AES_256_GCM_SHA384,TLS_RSA_WITH_AES_256_CBC_SHA256,TLS_RSA_WITH_AES_128_CBC_SHA,TLS_KRB5_EXPORT_WITH_RC2_CBC_40_SHA,TLS_DH_DSS_WITH_AES_128_CBC_SHA,TLS_KRB5_EXPORT_WITH_RC4_40_SHA</value><final>true</final><description>Inserted by Durga on 8/14/18 for TLS Hardening project</description></property>


hue_server_hue_safety_valve 

[desktop] ssl_cipher_list=ECDHE-ECDSA-CHACHA20-POLY1305:ECDHE-RSA-CHACHA20-POLY1305:ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384:DHE-RSA-AES128-GCM-SHA256:DHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-AES128-SHA256:ECDHE-RSA-AES128-SHA256:ECDHE-ECDSA-AES128-SHA:ECDHE-RSA-AES256-SHA384:ECDHE-RSA-AES128-SHA:ECDHE-ECDSA-AES256-SHA384:ECDHE-ECDSA-AES256-SHA:ECDHE-RSA-AES256-SHA:DHE-RSA-AES128-SHA256:DHE-RSA-AES128-SHA:DHE-RSA-AES256-SHA256:DHE-RSA-AES256-SHA:AES128-GCM-SHA256:AES256-GCM-SHA384:AES128-SHA256:AES256-SHA256:AES128-SHA:AES256-SHA:!DSS  


secure=true Enable tagging of secure flag to the users' session ID cookie. Prevents man-in-middle attack.
http-only=true Enable tagging of http-only flag to the users' session ID cookie. Prevents cross-site scripting vulnerability.
expire_at_browser_close=true Terminate Hue logon session after user closed the browser.
ttl=86400 Expire the users' session ID cookie after 1 day (24 hours).

[desktop] 
app_blacklist=spark,rdbms,sqoop,zookeeper,hbase 
use_x_forwarded_host=True 
ssl_validate=False  
ssl_cipher_list=ECDHE-ECDSA-CHACHA20-POLY1305:ECDHE-RSA-CHACHA20-POLY1305:ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384:DHE-RSA-AES128-GCM-SHA256:DHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-AES128-SHA256:ECDHE-RSA-AES128-SHA256:ECDHE-ECDSA-AES128-SHA:ECDHE-RSA-AES256-SHA384:ECDHE-RSA-AES128-SHA:ECDHE-ECDSA-AES256-SHA384:ECDHE-ECDSA-AES256-SHA:ECDHE-RSA-AES256-SHA:DHE-RSA-AES128-SHA256:DHE-RSA-AES128-SHA:DHE-RSA-AES256-SHA256:DHE-RSA-AES256-SHA:ECDHE-ECDSA-DES-CBC3-SHA:ECDHE-RSA-DES-CBC3-SHA:EDH-RSA-DES-CBC3-SHA:AES128-GCM-SHA256:AES256-GCM-SHA384:AES128-SHA256:AES256-SHA256:AES128-SHA:AES256-SHA:DES-CBC3-SHA:!DSS:!DH:!ADH:!DES:!3DES 
[[auth]] 
idle_session_timeout=600 
ignore_username_case=True 
force_username_lowercase=True
login_failure_limit=3 
login_lock_out_at_failure=true 
login_cooloff_time=1800
login_lock_out_by_combination_browser_user_agent_and_ip=true
login_lock_out_by_combination_user_and_ip=true 
[[ldap]] 
debug=False 
debug_level=255 
trace_level=9 
ignore_username_case=true 
force_username_lowercase=true 
[[session]] 
secure=True 
ttl=14400 
http_only=True  
expire_at_browser_close=True 
[[ssl]] 
validate=False 

Impala Daemon Command Line Argument Advanced Configuration Snippet (Safety Valve):
--ssl_minimum_version=tlsv1.2
--ssl_cipher_list=ECDH+AESGCM:DH+AESGCM:ECDH+AES256:DH+AES256:ECDH+AES128:DH+AES:RSA+AESGCM:RSA+AES:!aNULL:!MD5:!DSS:!3DES:!DES:!SHA


Kudu

There are two ports to configure for Kudu, the rpc protocol port and the webserver protocol port. In CDH 5.13.1 it’s possible to restrict the TLS protocol to TLS 1.2 for the rpc protocol port. This is the port where that all the data travels through. Unfortunately it’s not possible to similarly enforce TLS 1.2 on the web server port in CDH 5.13.1. The traffic that goes over the web server port is of a generally non-sensitive nature - like status.

Like Impala, there are two different solutions depending on the OS version. For RHEL/CentOS 7, do this:

Step 5a: Kudu on RHEL/CentOS 7
In CM, add the following parameter to the “Kudu Service Advanced Configuration Snippet (Safety Valve) for gflagfile”
-rpc_tls_min_protocol=TLSv1.2

On RHEL/CentOS 6, add the following instead:

Step 5b: Kudu on RHEL/CentOS 6
In CM, add the following parameter to the “Kudu Service Advanced Configuration Snippet (Safety Valve) for gflagfile”
-rpc_tls_ciphers=DEFAULT:!aNULL:!eNULL:!LOW:!EXPORT:!SSLv2:!SSLv3:!TLSv1




