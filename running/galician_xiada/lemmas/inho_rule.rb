# frozen_string_literal: true
require_relative '../../bin/lemmas/rule'
require_relative 'utils'

module Lemmas
  class InhoRule < Rule
    include Utils

    def initialize(all_possible_tags)
      super(all_possible_tags)
      @default_tags = tags_for('Sc.*', 'A.*', 'V0p0.*', 'V0x000', 'W.*', 'I.*').freeze
      @v_tags = tags_for('V.i.*','V.s','V0m.*').freeze
      @sfc_a0f_tags = tags_for('Scf.*','A0f.*').freeze
      @sa_tags = tags_for('S.*', 'A.*').freeze
      @sai_tags = tags_for('S.*', 'A.*', 'I.*').freeze
      @saiw_tags = tags_for('S.*', 'A.*', 'I.*', 'W.*').freeze
      @saiv_tags = tags_for('S.*', 'A.*', 'I.*', 'V0p0.*').freeze
      @sav_tags = tags_for('S.*', 'A.*', 'V0p0.*').freeze
    end

    def apply_query(query)
      return unless query.word.match(/(.*(.))iñ([oa])(s?)\z/) && !query.word.include?('-')

      base, suffix, g, n = Regexp.last_match.captures

      case
      when base.end_with?('gu') then apply_gu(query, base, g, n)
      when base.end_with?('lc') then apply_lc(query, base, g, n)
      when base.end_with?('qu') then apply_qu(query, base, g, n)
      when base.end_with?('onc') then apply_onc(query, base, g, n)
      when base.end_with?('anc') then apply_anc(query, base, g, n)
      when base.end_with?('enc') && g == 'a' then apply_enc_a(query, base, g, n)
      when base.end_with?('inc') then apply_inc(query, base, g, n)
      when base.end_with?('nd') then apply_nd(query, base, g, n)
      when base.end_with?('rc') then apply_rc(query, base, g, n)
      when %w[f m v x].include?(suffix) then apply_fmvx(query, base, g, n)
      when base.end_with?('t') then apply_t(query, base, g, n)
      when %w[b p ñ].include?(suffix) then apply_bpnh(query, base, g, n)
      when base.end_with?('ch') then apply_ch(query, base, g, n)
      when base.end_with?('ll') then apply_ll(query, base, g, n)
      when base.end_with?('rr') then apply_rr(query, base, g, n)
      when base.end_with?('d') then apply_d(query, base, g, n)
      when base.end_with?('ues') then apply_ues(query, base, g, n)
      when base.end_with?('s') then apply_s(query, base, g, n)
      else apply_default(query, base, g, n)
      end
    end

    def apply_result(query, result)
      g, n = query.prev.word.match(/iñ([oa])(s?)\z/).captures

      # Forcefully replace gender and number of the tag based on the original word gender and number
      # TODO: Investigate if it is better to perform the search with the correct tags to begin with
      result.copy(replace_tag_gn(result.tag, g, n))
    end

    private


    # amiguiño => amigo
    # enruguiñas => enruga
    # albondiguiñas => albóndiga
    # estomaguiño => estómago
    def apply_gu(query, base, g, n)
      tilde_variants("#{base.delete_suffix('u')}#{g}#{n}").map { |v| query.copy(v, @default_tags) }
    end

    # solciño => sol (Scms)
    # animalciños => animal (Scmp)
    # descalciña => descalzo
    def apply_lc(query, base, g, n)
      search_base = base.delete_suffix('c')
      common_sp_query = query.copy("#{search_base}z#{g}#{n}", @default_tags)
      if n == 's' # When plural
        [query.copy("#{search_base}es", @default_tags), common_sp_query]
      else
        [query.copy(search_base, @default_tags), common_sp_query]
      end
    end

    # quiño/a/os/as
    # plaquiñas => placas
    # retaquiños => retacos
    # musiquiña => música
    # musiquiño => músico
    # faisquiñas => faíscas
    # periodiquiños => periódicos
    # politiquiñas => políticas
    # bosquiños => bosques
    def apply_qu(query, base, g, n)
      search_base = "#{base.delete_suffix('qu')}c#{g}#{n}"
      [query.copy(search_base, @default_tags),
       *tilde_variants(search_base).map { |v| query.copy(v, @default_tags) },
       query.copy(search_base, @v_tags),
       query.copy("#{base}e#{n}", @default_tags)]
    end

    def apply_onc(query, base, g, n)
      if g == 'o'
        # algodonciño => algodón
        # cartonciños => cartóns
        query.copy("#{base.delete_suffix('onc')}ón#{n}", @default_tags)
      else
        # cancionciña => canción
        # chaponciñas => chaponas
        search_base = base.delete_suffix('onc')
        [query.copy("#{search_base}ón#{n}", @sfc_a0f_tags),
         query.copy("#{search_base}ona#{n}", @sfc_a0f_tags)]
      end
    end

    # garavanciño => garavanzo
    # crianciñas => crianzas
    # vranciño => vran
    def apply_anc(query, base, g, n)
      search_base = base.delete_suffix('anc')
      [query.copy("#{search_base}anz#{g}#{n}", @default_tags),
       query.copy("#{search_base}án#{n}", @default_tags),
       query.copy("#{search_base}an#{n}", @default_tags)]
    end

    # trenciñas => tranzas
    # fervenciña => fervenza
    def apply_enc_a(query, base, g, n)
      query.copy("#{base.delete_suffix('c')}z#{g}#{n}", @default_tags)
    end

    # pinciñas => pinzas
    # xardinciños => xardíns
    def apply_inc(query, base, g, n)
      search_base = base.delete_suffix('inc')
      [query.copy("#{search_base}inz#{g}#{n}", @default_tags),
       query.copy("#{search_base}ín#{n}", @default_tags)]
    end

    # segundiño => segundo
    # brandiños => brandos
    # pasandiño => pasando
    # meirandiño => meirande
    def apply_nd(query, base, g, n)
      [query.copy("#{base}#{g}#{n}", @default_tags),
       query.copy("#{base}e#{n}", @saiv_tags)]
    end

    def apply_rc(query, base, g, n)
      # cogorciña => cogorza
      # verciñas => verzas
      # almorciño => almorzo
      search_base = base.delete_suffix('c')
      common_sp_query = query.copy("#{search_base}z#{g}#{n}", @sa_tags)
      if n == 's' # When plural
        # calamarciños => calamares
        [common_sp_query, query.copy("#{search_base}es", @sa_tags)]
      else
        # calorciño => calor
        # altarciño => altar
        # amorciño => amor
        [common_sp_query, query.copy(search_base, @sa_tags)]
      end
    end

    # xefiño => xefe
    # lumiño => lume
    # suaviñas => suaves
    # traxiños => traxes
    def apply_fmvx(query, base, g, n)
      [query.copy("#{base}#{g}#{n}", @sai_tags),
       query.copy("#{base}e", @sai_tags)]
    end

    # gatiños => gatos
    # azoutiña => azouta
    # tomatiños => tomates
    # amantiñas => amantes
    def apply_t(query, base, g, n)
      [query.copy("#{base}#{g}#{n}", @saiw_tags),
       query.copy("#{base}e#{n}", @sav_tags)]
    end

    def apply_bpnh(query, base, g, n)
      common_suffix_query = query.copy("#{base}#{g}#{n}", @sav_tags)
      if base.end_with?('b')
        # barbiña => barba
        # xoubiñas => xouba
        # FIXME: Intended rule was: nubiñas => nubes
        # nubiñas => nube
        [common_suffix_query, query.copy("#{base}e", @sav_tags)]
      else
        # trapiño => trapo
        # castañiñas => castañas
        # viñiño => viño
        common_suffix_query
      end
    end

    # estuchiño => estuche
    # churriñas => churras
    def apply_ch(query, base, g, n)
      [query.copy("#{base}e", @sav_tags),
       query.copy("#{base}#{g}#{n}", @sav_tags)]
    end

    # ovelliñas => ovellas
    def apply_ll(query, base, g, n)
      query.copy("#{base}#{g}#{n}", @sav_tags)
    end

    # aforriños => aforros
    def apply_rr(query, base, g, n)
      query.copy("#{base}#{g}#{n}", @sav_tags)
    end

    # cadradiños => cadrados
    # todiñas => todas
    # bigodiño => bigode
    # humildiño => humilde
    def apply_d(query, base, g, n)
      [query.copy("#{base}#{g}#{n}", @saiv_tags),
       query.copy("#{base}e#{n}", @saiv_tags)]
    end

    def apply_ues(query, base, g, n)
      search_base = base.delete_suffix('es')
      if n == ''
        if g == 'o'
          # marquesiño => marqués
          query.copy("#{search_base}és", @sav_tags)
        elsif g == 'a'
          # marquesiña => marquesa
          query.copy("#{search_base}esa", @sav_tags)
        end
      else # When plural
        if g == 'o'
          # marquesiños => marqueses
          query.copy("#{search_base}eses", @sav_tags)
        else
          # marquesiñas => marquesas
          query.copy("#{search_base}esas", @sav_tags)
        end
      end
    end

    # tesiños => tesos
    # raposiña => raposa
    # camisiñas => camisas
    # tesiña => tese
    # tosiña => tose
    def apply_s(query, base, g, n)
      [query.copy("#{base}#{g}#{n}", @sav_tags),
       query.copy("#{base}e#{n}", @sav_tags)]
    end

    # horiña, peliños, groliño, etc.
    def apply_default(query, base, g, n)
      query.copy("#{base}#{g}#{n}", @default_tags)
    end
  end
end
