{% from 'ezjail/map.jinja' import lookup %}
{% from 'ezjail/map.jinja' import options %}

{% if options.jails is defined %}
{% for jail, args in options.jails.items() %}

{% set jail_extra_args = '' %}

{% if args.flavour is defined %}
{% set jail_extra_args = jail_extra_args + '-f ' + args.flavour %}
{% endif %}

ezjail.jails.{{ jail }}.configure:
  cmd.run:
    - name: 'ezjail-admin create {{ jail_extra_args }} {{ jail }} "{{ args.networks|join(',') }}"'
    - creates: '{{ salt['file.join'](options.jaildir, jail) }}'
    - require:
      - service: 'ezjail.service'

{% if args.salted is defined and args.salted.grains is defined %}
ezjail.jails.{{ jail }}.configure.grains:
  file.managed:
    - name: '{{ lookup.config.path }}'
    - name: '{{ salt['file.join'](options.jaildir, jail, 'usr/local/etc/salt/grains') }}'
    - source: 'salt://ezjail/files/grains'
    - template: 'jinja'
    - template_grains: {{ args['salted']['grains'] }}
    - require_on:
      - cmd: 'ezjail.jails.{{ jail }}.start'
{% endif %}

{% set enabled = args['enabled'] | default(True) %}
{% if enabled %}
ezjail.jails.{{ jail }}.start:
  cmd.run:
    - name: 'ezjail-admin start {{ jail }}'
    - unless: 'jls | grep {{ jail }}'
{% else %}
ezjail.jails.{{ jail }}.stop:
  cmd.run:
    - name: 'ezjail-admin stop {{ jail }}'
    - onlyif: 'jls | grep {{ jail }}'
{% endif %}

{% endfor %}
{% endif %}
