# frozen_string_literal: true
require_relative '../../bin/lemmas/rule'
require_relative 'utils'

module Lemmas
  class InhoRule < Rule
    include Utils

    def initialize(all_possible_tags)
      super(all_possible_tags)
      @tags = tags_for('Sc.*', 'A.*', 'V0p0.*', 'V0x000', 'W.*', 'I.*').freeze
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

      if base.end_with?('gu')
        # amiguiño => amigo
        # enruguiñas => enruga
        # albondiguiñas => albóndiga
        # estomaguiño => estómago
        tilde_variants("#{base.delete_suffix('u')}#{g}#{n}").map { |v| query.copy(v, @tags) }
      elsif base.end_with?('lc')
        # solciño => sol (Scms)
        # animalciños => animal (Scmp)
        # descalciña => descalzo
        search_base = base.delete_suffix('c')
        common_sp_query = query.copy("#{search_base}z#{g}#{n}", @tags)
        if n == 's' # When plural
          [query.copy("#{search_base}es", @tags), common_sp_query]
        else
          [query.copy(search_base, @tags), common_sp_query]
        end
      elsif base.end_with?('qu')
        # quiño/a/os/as
        # plaquiñas => placas
        # retaquiños => retacos
        # musiquiña => música
        # musiquiño => músico
        # faisquiñas => faíscas
        # periodiquiños => periódicos
        # politiquiñas => políticas
        # bosquiños => bosques
        search_base = "#{base.delete_suffix('qu')}c#{g}#{n}"
        [query.copy(search_base, @tags),
         *tilde_variants(search_base).map { |v| query.copy(v, @tags) },
         query.copy(search_base, @v_tags),
         query.copy("#{base}e#{n}", @tags)]
      elsif base.end_with?('onc')
        if g == 'o'
          # algodonciño => algodón
          # cartonciños => cartóns
          query.copy("#{base.delete_suffix('onc')}ón#{n}", @tags)
        else
          # cancionciña => canción
          # chaponciñas => chaponas
          search_base = base.delete_suffix('onc')
          [query.copy("#{search_base}ón#{n}", @sfc_a0f_tags),
           query.copy("#{search_base}ona#{n}", @sfc_a0f_tags)]
        end
      elsif base.end_with?('anc')
        # garavanciño => garavanzo
        # crianciñas => crianzas
        # vranciño => vran
        search_base = base.delete_suffix('anc')
        [query.copy("#{search_base}anz#{g}#{n}", @tags),
         query.copy("#{search_base}án#{n}", @tags),
         query.copy("#{search_base}an#{n}", @tags)]
      elsif base.end_with?('enc') && g == 'a'
        # trenciñas => tranzas
        # fervenciña => fervenza
        query.copy("#{base.delete_suffix('c')}z#{g}#{n}", @tags)
      elsif base.end_with?('inc')
        # pinciñas => pinzas
        # xardinciños => xardíns
        search_base = base.delete_suffix('inc')
        [query.copy("#{search_base}inz#{g}#{n}", @tags),
         query.copy("#{search_base}ín#{n}", @tags)]
      elsif base.end_with?('nd')
        # segundiño => segundo
        # brandiños => brandos
        # pasandiño => pasando
        # meirandiño => meirande
        [query.copy("#{base}#{g}#{n}", @tags),
         query.copy("#{base}e#{n}", @saiv_tags)]
      elsif base.end_with?('rc')
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
      elsif %w[f m v x].include?(suffix)
        # xefiño => xefe
        # lumiño => lume
        # suaviñas => suaves
        # traxiños => traxes
        [query.copy("#{base}#{g}#{n}", @sai_tags),
         query.copy("#{base}e", @sai_tags)]
      elsif base.end_with?('t')
        # gatiños => gatos
        # azoutiña => azouta
        # tomatiños => tomates
        # amantiñas => amantes
        [query.copy("#{base}#{g}#{n}", @saiw_tags),
         query.copy("#{base}e#{n}", @sav_tags)]
      elsif %w[b p ñ].include?(suffix)
        common_suffix_query = query.copy("#{base}#{g}#{n}", @sav_tags)
        if suffix == 'b'
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
      elsif base.end_with?('ch')
        # estuchiño => estuche
        # churriñas => churras
        [query.copy("#{base}e", @sav_tags),
         query.copy("#{base}#{g}#{n}", @sav_tags)]
      elsif base.end_with?('ll')
        # ovelliñas => ovellas
        query.copy("#{base}#{g}#{n}", @sav_tags)
      elsif base.end_with?('rr')
        # aforriños => aforros
        query.copy("#{base}#{g}#{n}", @sav_tags)
      elsif base.end_with?('d')
        # cadradiños => cadrados
        # todiñas => todas
        # bigodiño => bigode
        # humildiño => humilde
        [query.copy("#{base}#{g}#{n}", @saiv_tags),
         query.copy("#{base}e#{n}", @saiv_tags)]
      elsif base.end_with?('ues')
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
      elsif base.end_with?('s')
        # tesiños => tesos
        # raposiña => raposa
        # camisiñas => camisas
        # tesiña => tese
        # tosiña => tose
        [query.copy("#{base}#{g}#{n}", @sav_tags),
         query.copy("#{base}e#{n}", @sav_tags)]
      else
        # horiña, peliños, groliño, etc.
        query.copy("#{base}#{g}#{n}", @tags)
      end
    end

    def apply_result(query, result)
      g, n = query.prev.word.match(/iñ([oa])(s?)\z/).captures

      # Forcefully replace gender and number of the tag based on the original word gender and number
      # TODO: Investigate if it is better to perform the search with the correct tags to begin with
      result.copy(replace_tag_gn(result.tag, g, n))
    end
  end
end
